/*
  A configurable logging framework for Chapel programs.

  Provides leveled logging (``ERROR``, ``WARNING``, ``INFO``, ``DEBUG``) with
  customizable output streams, formatting, and color support. Log levels can be
  controlled at runtime via environment variables.

  **Quick start:**

  .. code-block:: chapel

     import Log;
     import Log.{MN, RN, LN};

     var log = new Log.logger("myApp");
     log.info("Application started");
     log.warn("Something looks odd");
     log.error("Something went wrong");

     // Include source location information:
     log.info(MN(), RN(), LN(), "message with location");

  **Key features:**

  * Extensible for custom log formats and outputs by subclassing
    :type:`LogStream` and :type:`LogFormat`

  * Automatic runtime log level control via environment variables
    (e.g. ``MYAPP_LOG_LEVEL=debug``)

  * Built-in color support with support for auto-detection of TTY output
    and customizable color schemes

  * Built-in log format/stream options to cover common use cases
    (e.g. :type:`StderrStream`, :type:`FileStream`, :type:`JsonFormat`)

*/
@chpldoc.noUsage
@chpldoc.noAutoInclude
module Log {
  import TerminalColors;
  import TerminalColors.{styledText, style, reset};
  import TemplateString.templateString;
  use IO;
  import Time.{dateTime};
  public use Reflection only
    getModuleName as MN,
    getRoutineName as RN,
    getLineNumber as LN;

  /*
    Represents the severity level of a log message.

    Levels are ordered from least to most verbose:
    ``NONE < ERROR < WARNING < INFO < DEBUG``.

    Setting a logger's level to a given value enables all messages at that level
    and below. For example, ``INFO`` enables ``INFO``, ``WARNING``, and
    ``ERROR`` messages. ``NONE`` disables all logging.
  */
  enum LogLevel {
    /**/
    NONE,
    /**/
    ERROR,
    /**/
    WARNING,
    /**/
    INFO,
    /**/
    DEBUG
  }
  @chpldoc.nodoc
  proc LogLevel.formatted(): string {
    return (this:string).toLower();
  }
  @chpldoc.nodoc
  proc type LogLevel.makeEnvName(name: string): string {
    var NAME: string;
    for c in name.toUpper().bytes() {
      if (c < 'A'.toByte() || c > 'Z'.toByte()) &&
         (c < '0'.toByte() || c > '9'.toByte()) {
        NAME.appendCodepointValues('_'.toByte());
      } else {
        NAME.appendCodepointValues(c);
      }
    }
    return NAME + "_LOG_LEVEL";
  } // proc type LogLevel.makeEnvName(name: string): string
  @chpldoc.nodoc
  proc type LogLevel.fromEnv(envVar: string, default: LogLevel): LogLevel {
    import OS, OS.POSIX, CTypes;
    const logLevelChar = OS.POSIX.getenv(envVar.c_str());
    if logLevelChar != nil {
      try {
        const s = string.createCopyingBuffer(logLevelChar).toUpper();
        return s:LogLevel;
      } catch {
        return default;
      }
    }
    return default;
  }


  /*
    The primary interface for emitting log messages.

    Create a ``logger`` with a name and optional configuration, then call its
    level methods (:proc:`~logger.info`, :proc:`~logger.warn`,
    :proc:`~logger.error`, :proc:`~logger.debug`) to emit messages.

    .. code-block:: chapel

      var log = new Log.logger("myApp");
      log.info("server started on port ", port);
      log.error("connection failed");

  */
  record logger {
    /* The display name for this logger, included in formatted output. */
    var name: string;
    /*
      The current log level threshold.
      Messages below this level are discarded.
    */
    var logLevel: LogLevel;
    /*
      The output stream where formatted log messages are written.

      See :type:`LogStream` and its subclasses for built-in stream types, or
      subclass :type:`LogStream` to implement custom log destinations.
    */
    var stream: shared LogStream;
    /*
      The formatter used to produce log message strings.

      See :type:`LogFormat` and its subclasses for built-in formatters, or
      subclass :type:`LogFormat` to implement custom formatting logic.
    */
    var format: shared LogFormat;

    /*
      Create a new logger.

      :arg name: A display name for this logger, also used to derive the
        default environment variable name (e.g. ``"myApp"`` checks
        ``MY_APP_LOG_LEVEL``).
      :arg logLevel: The default log level. Overridden by the environment
        variable if set. Defaults to ``LogLevel.INFO``.
      :arg colorMode: Controls ANSI color output. Defaults to ``AUTO``,
        which enables color when the output stream is a TTY.
      :arg logLevelEnvVar: The environment variable name to check for a
        runtime log level override. Defaults to ``<NAME>_LOG_LEVEL``
        (uppercased, non-alphanumeric characters replaced with ``_``).
      :arg stream: The output stream. Pass ``nil`` (default) to log use the
        default output stream (:type:`LogStream`), or another subclass of
        :type:`LogStream`.
      :arg format: The log formatter. Pass ``nil`` (default) to use the
        standard format (:type:`LogFormat`), or another subclass of
        :type:`LogFormat`.
    */
    @chpldoc.noWhereClause
    proc init(name: string,
              logLevel: LogLevel = LogLevel.INFO,
              colorMode: ColorMode = ColorMode.AUTO,
              logLevelEnvVar: string = LogLevel.makeEnvName(name),
              in stream: LogStream? = nil:shared LogStream?,
              in format: LogFormat? = nil:shared LogFormat?)
    where (isOwnedClass(stream) || isSharedClass(stream) ||
           isUnmanagedClass(stream)) &&
          (isOwnedClass(format) || isSharedClass(format) ||
           isUnmanagedClass(format)) {
      this.name = name;
      this.logLevel = LogLevel.fromEnv(logLevelEnvVar, logLevel);
      // we know these casts cannot throw because we check before the cast
      this.stream = try! if stream
                        then if isSharedClass(stream)
                              then stream:class
                              else shared.adopt(stream):class
                        else new shared LogStream();
      this.format =
        try! if format
          then if isSharedClass(format)
                then format:class
                else shared.adopt(format):class
          else new shared LogFormat();
      init this;
      this.format.setUseColor(colorMode, this.stream);
    }

    @chpldoc.nodoc
    proc report(level: LogLevel,
                message: string,
                moduleName: string = "<unknown>",
                routineName: string = "<unknown>",
                lineNumber: int = 0) {
      const timestamp = dateTime.now();
      const formattedMessage = format.format(timestamp, level, moduleName,
                                              routineName, lineNumber,
                                              name, message);
      stream.write(formattedMessage);
    }
    /*
      Log a message at the ``INFO`` level. Accepts any number of arguments,
      which are stringified and concatenated. Use the overload with
      ``moduleName``, ``routineName``, and ``lineNumber`` to include source
      location in the output (pass ``MN()``, ``RN()``, ``LN()``, respectively,
      for automatic capture).

      The ``infof`` variant accepts a format string followed by arguments,
      using Chapel's `formatted I/O <https://chapel-lang.org/docs/modules/standard/IO/FormattedIO.html#about-io-formatted-io>`_ syntax.
    */
    proc info(message...) {
      if logLevel >= LogLevel.INFO then
        report(LogLevel.INFO, chpl_stringify_wrapper((...message)));
    }
    /**/
    proc infof(format: string, args...) {
      if logLevel >= LogLevel.INFO {
        var message: string;
        try {
          message = format.format((...args));
        } catch e {
          message = "format error: '" + e.message() +
                    "' while formatting message with format='" + format +
                    "' and args=" + chpl_stringify_wrapper((...args));
        }
        report(LogLevel.INFO, message);
      }
    }
    /**/
    proc info(moduleName: string,
              routineName: string,
              lineNumber: int,
              message...) {
      if logLevel >= LogLevel.INFO then
        report(LogLevel.INFO, chpl_stringify_wrapper((...message)),
               moduleName, routineName, lineNumber);
    }
    /**/
    proc infof(moduleName: string,
               routineName: string,
               lineNumber: int,
               format: string, args...) {
      if logLevel >= LogLevel.INFO {
        var message: string;
        try {
          message = format.format((...args));
        } catch e {
          message = "format error: '" + e.message() +
                    "' while formatting message with format='" + format +
                    "' and args=" + chpl_stringify_wrapper((...args));
        }
        report(LogLevel.INFO, message,
               moduleName, routineName, lineNumber);
      }
    }

    /*
      Log a message at the ``DEBUG`` level. This is the most verbose level and
      is typically used for development diagnostics. Only emitted when the
      logger's level is ``DEBUG``.

      Accepts the same overloads as :proc:`~logger.info`.
    */
    proc debug(message...) {
      if logLevel >= LogLevel.DEBUG then
        report(LogLevel.DEBUG, chpl_stringify_wrapper((...message)));
    }
    /**/
    proc debugf(format: string, args...) {
      if logLevel >= LogLevel.DEBUG {
        var message: string;
        try {
          message = format.format((...args));
        } catch e {
          message = "format error: '" + e.message() +
                    "' while formatting message with format='" + format +
                    "' and args=" + chpl_stringify_wrapper((...args));
        }
        report(LogLevel.DEBUG, message);
      }
    }
    /**/
    proc debug(moduleName: string,
              routineName: string,
              lineNumber: int,
              message...) {
      if logLevel >= LogLevel.DEBUG then
        report(LogLevel.DEBUG, chpl_stringify_wrapper((...message)),
               moduleName, routineName, lineNumber);
    }
    /**/
    proc debugf(moduleName: string,
               routineName: string,
               lineNumber: int,
               format: string, args...) {
      if logLevel >= LogLevel.DEBUG {
        var message: string;
        try {
          message = format.format((...args));
        } catch e {
          message = "format error: '" + e.message() +
                    "' while formatting message with format='" + format +
                    "' and args=" + chpl_stringify_wrapper((...args));
        }
        report(LogLevel.DEBUG, message,
               moduleName, routineName, lineNumber);
      }
    }

    /*
      Log a message at the ``WARNING`` level. Use for potentially harmful
      situations that do not prevent normal operation.

      Accepts the same overloads as :proc:`~logger.info`.
    */
    proc warn(message...) {
      if logLevel >= LogLevel.WARNING then
        report(LogLevel.WARNING, chpl_stringify_wrapper((...message)));
    }
    /**/
    proc warnf(format: string, args...) {
      if logLevel >= LogLevel.WARNING {
        var message: string;
        try {
          message = format.format((...args));
        } catch e {
          message = "format error: '" + e.message() +
                    "' while formatting message with format='" + format +
                    "' and args=" + chpl_stringify_wrapper((...args));
        }
        report(LogLevel.WARNING, message);
      }
    }
    /**/
    proc warn(moduleName: string,
              routineName: string,
              lineNumber: int,
              message...) {
      if logLevel >= LogLevel.WARNING then
        report(LogLevel.WARNING, chpl_stringify_wrapper((...message)),
               moduleName, routineName, lineNumber);
    }
    /**/
    proc warnf(moduleName: string,
               routineName: string,
               lineNumber: int,
               format: string, args...) {
      if logLevel >= LogLevel.WARNING {
        var message: string;
        try {
          message = format.format((...args));
        } catch e {
          message = "format error: '" + e.message() +
                    "' while formatting message with format='" + format +
                    "' and args=" + chpl_stringify_wrapper((...args));
        }
        report(LogLevel.WARNING, message,
               moduleName, routineName, lineNumber);
      }
    }

    /*
      Log a message at the ``ERROR`` level. Use for error conditions that
      may still allow the program to continue.

      Accepts the same overloads as :proc:`~logger.info`.
    */
    proc error(message...) {
      if logLevel >= LogLevel.ERROR then
        report(LogLevel.ERROR, chpl_stringify_wrapper((...message)));
    }
    /**/
    proc errorf(format: string, args...) {
      if logLevel >= LogLevel.ERROR {
        var message: string;
        try {
          message = format.format((...args));
        } catch e {
          message = "format error: '" + e.message() +
                    "' while formatting message with format='" + format +
                    "' and args=" + chpl_stringify_wrapper((...args));
        }
        report(LogLevel.ERROR, message);
      }
    }
    /**/
    proc error(moduleName: string,
              routineName: string,
              lineNumber: int,
              message...) {
      if logLevel >= LogLevel.ERROR then
        report(LogLevel.ERROR, chpl_stringify_wrapper((...message)),
               moduleName, routineName, lineNumber);
    }
    /**/
    proc errorf(moduleName: string,
               routineName: string,
               lineNumber: int,
               format: string, args...) {
      if logLevel >= LogLevel.ERROR {
        var message: string;
        try {
          message = format.format((...args));
        } catch e {
          message = "format error: '" + e.message() +
                    "' while formatting message with format='" + format +
                    "' and args=" + chpl_stringify_wrapper((...args));
        }
        report(LogLevel.ERROR, message,
               moduleName, routineName, lineNumber);
      }
    }

    /*
      Flush the output stream, ensuring that all buffered log messages are
      written out. This can be useful to call before program exit to ensure all
      logs are captured, or after critical log messages to ensure they are not
      lost if the program crashes.
    */
    proc flush() {
      stream.flush();
    }
  }


  /*
    Base class for log output destinations. ``LogStream`` can be subclassed to
    override and customize aspects of the log output.

    The default implementation writes log messages to ``stdout``.

    **Customization points for subclasses:**

    * Override :proc:`~LogStream.write` to change how messages are written.

    * Override :proc:`~LogStream.flush` to control flushing behavior.

    * Override :proc:`~LogStream.handleError` to implement custom error handling
      when I/O errors occur during writing or flushing.

    * Override :proc:`~LogStream.getFile` to return the underlying ``file`` for
      this stream. This is important for proper auto-color detection when using
      :enum:`ColorMode.AUTO`.
  */
  class LogStream {
    /**/
    proc write(message: string) {
      try {
        stdout.writeln(message);
      } catch e {
        handleError(e, (message,));
      }
    }
    /**/
    proc flush() {
      try {
        stdout.flush();
      } catch e {
        handleError(e, none);
      }
    }
    /**/
    proc handleError(error, args) {
      if args.type == nothing then
        try! stderr.writeln("Error logging: ", error);
      else
        try! stderr.writeln("Error logging: ", error, "; args=", args);
    }
    /*
      Return the underlying ``file`` for this stream.
    */
    proc getFile(): file do
      return stdout.getFile();
  }
  /*
    A :type:`LogStream` that writes log messages to ``stderr``
    instead of ``stdout``.
  */
  class StderrStream: LogStream {
    /**/
    override proc write(message: string) {
      try {
        stderr.writeln(message);
      } catch e {
        handleError(e, (message,));
      }
    }
    /**/
    override proc flush() {
      try {
        stderr.flush();
      } catch e {
        handleError(e, none);
      }
    }
    /**/
    override proc getFile(): file do
      return stderr.getFile();
  }
  /*
    A :type:`LogStream` that writes log messages to a file.

    .. code-block:: chapel

      var log = new Log.logger("app",
                                   stream=new Log.FileStream("app.log"));

  */
  class FileStream: LogStream {
    @chpldoc.nodoc
    var outFile: file;
    @chpldoc.nodoc
    var writer: fileWriter(locking=true);
    /*
      Create a ``FileStream`` that writes to the given file path.
      The file is created or truncated on open.

      :arg filename: The path to the log file.
    */
    proc init(filename: string) {
      init this;
      openFiles(filename);
    }
    @chpldoc.nodoc
    proc openFiles(filename: string) {
      try {
        outFile = open(filename, ioMode.cw);
        writer = outFile.writer(locking=true);
      } catch e {
        try! stderr.writeln("Error opening log file: ", e.message());
      }
    }
    @chpldoc.nodoc
    proc deinit() {
      try {
        writer.close();
        outFile.close();
      } catch e {
        try! stderr.writeln("Error closing log file: ", e.message());
      }
    }
    /**/
    override proc write(message: string) {
      try {
        writer.writeln(message);
      } catch e {
        handleError(e, (message,));
      }
    }
    /**/
    override proc flush() {
      try {
        writer.flush();
      } catch e {
        handleError(e, none);
      }
    }
    /**/
    override proc getFile(): file do
      return outFile;
  }
  /*
    A :type:`FileStream` that writes log entries as a JSON array to a file.

    The output file contains a JSON object with a ``"logs"`` key holding an
    array of entries. Pair with :type:`JsonFormat` to produce valid JSON
    log entries.

    .. code-block:: chapel

      var log = new Log.logger("app",
                                   stream=new Log.JsonStream("app.json"),
                                   format=new Log.JsonFormat());

  */
  class JsonStream: FileStream {
    @chpldoc.nodoc
    var sep: string = "";

    /*
      Create a ``JsonStream`` that writes JSON log entries to the given file.

      :arg filename: The path to the JSON log file.
    */
    proc init(filename: string) {
      super.init(filename);
      init this;
      writeHeader();
    }
    @chpldoc.nodoc
    proc writeHeader() {
      try {
        writer.write("{\"logs\":[\n");
      } catch e {
        try! stderr.writeln("Error writing log file header: ", e.message());
      }
    }
    @chpldoc.nodoc
    proc deinit() {
      try {
        writer.write("\n]}\n");
      } catch e {
        try! stderr.writeln("Error writing log file footer: ", e.message());
      }
    }
    /*
      Write a JSON log entry to the file. The ``message`` argument should
      already be a valid JSON object string (as produced by
      :type:`JsonFormat`).
    */
    override proc write(message: string) {
      try {
        writer.write(sep, message:string);
        sep = ",\n";
      } catch e {
        handleError(e, (message,));
      }
    }
  }

  /*
    Controls whether ANSI color escape codes are included in log output.
  */
  enum ColorMode {
    /* Enable color when the output stream is connected to a TTY. */
    AUTO,
    /* Always include ANSI color codes. */
    ALWAYS,
    /* Never include color codes (plain text output). */
    NEVER
  }

  @chpldoc.nodoc
  proc computeUseColor(colorMode: ColorMode,
                       stream: borrowed LogStream?): bool {
    return colorMode == ColorMode.ALWAYS ||
            (colorMode == ColorMode.AUTO &&
             stream != nil && stream!.getFile().isAtty());
  }

  /*
    Controls how log messages are formatted before being written to a
    :type:`LogStream`.

    The format is defined by a template string containing placeholders
    delimited by ``%``. The following placeholders are available:

    * ``%T%`` — timestamp (``dateTime`` cast to string)
    * ``%LL%`` — log level (e.g. ``info``, ``error``)
    * ``%M%`` — module name
    * ``%R%`` — routine name
    * ``%N%`` — line number
    * ``%NAME%`` — logger name
    * ``%m%`` — the log message

    The default format string is ``"%T% %M%.%R%:%N% [%LL%] - %m%"``.

    For example, the following creates a logger that produces messages like
    ``"myApp [info]: message"``:

    .. code-block:: chapel

      var fmt = new Log.LogFormat("%NAME% [%LL%]: %m%");
      var log = new Log.logger("app", format=fmt);

    **Customization points for subclasses:**

    * Override :proc:`~LogFormat.format` for complete control over message
      formatting.
    * Override :proc:`~LogFormat.styleForTimestamp` to change the styling of
      the timestamp portion of the output.
    * Override :proc:`~LogFormat.styleForLogName` to change the styling of the
      logger
      name in the output.
    * Override :proc:`~LogFormat.styleForLogLevel` to change the styling of the
      log level label in the output.

  */
  class LogFormat {
    /* The compiled template string used to produce log messages. */
    var formatString: templateString;
    /* Whether ANSI color codes are applied to the formatted output. */
    var useColor: bool;

    /*
      Create a ``LogFormat`` with the given template string.

      :arg formatString: A template string with ``%``-delimited placeholders.
    */
    proc init(formatString: string = "%T% %M%.%R%:%N% [%LL%] - %m%",
              useColor: bool = false) {
      // we know this cannot throw because the prefixes are valid
      this.formatString = try! new templateString(formatString, ("%", "%"));
      this.useColor = useColor;
    }
    /*
      Compute whether color should be used based on the given mode and stream.

      This is called automatically by the logger at initialization, but can be
      called manually to update color usage if the output stream changes or if
      you want to change color modes at runtime.

      :arg colorMode: The color mode to use
      :arg stream: The output stream that will be printing the log messages.
    */
    proc setUseColor(colorMode: ColorMode, stream: borrowed LogStream? = nil) {
      this.useColor = computeUseColor(colorMode, stream);
    }

    /*
      Produce a formatted log message string from the given components.
      Override this method in a subclass for complete control over how log
      messages are formatted.
    */
    proc format(timestamp: dateTime, level: LogLevel,
                moduleName: string, routineName: string, lineNumber: int,
                loggerName: string, message: string): string {
      const formattedLL =
        if useColor
          then styleForLogLevel(level).finish() + level.formatted() + reset()
          else level.formatted();
      const formattedName =
        if useColor
          then styleForLogName(level).finish() + loggerName + reset()
          else loggerName;
      const formattedTimestamp =
        if useColor
          then styleForTimestamp(level).finish() + timestamp:string + reset()
          else timestamp:string;
      try {
        return formatString([
          "T" => formattedTimestamp,
          "LL" => formattedLL,
          "M" => moduleName,
          "R" => routineName,
          "N" => lineNumber:string,
          "NAME" => formattedName,
          "m" => message
        ]);
      } catch e {
        return "LogFormat error: '" + e.message() +
               "' while formatting message: " + message;
      }
    }

    /*
      Returns the `styledText <https://jabraham17.github.io/TerminalColors/index.html#styledText>`_
      applied to the timestamp in the formatted output.
      Override in a subclass to customize.
    */
    @chplcheck.ignore("UnusedFormal")
    proc styleForTimestamp(level: LogLevel): styledText {
      return style().fg(TerminalColors.cyan()).dim();
    }

    /*
      Returns the `styledText <https://jabraham17.github.io/TerminalColors/index.html#styledText>`_
      applied to the logger name in the formatted output.
      Override in a subclass to customize.
    */
    @chplcheck.ignore("UnusedFormal")
    proc styleForLogName(level: LogLevel): styledText {
      return style().bold();
    }

    /*
      Returns the `styledText <https://jabraham17.github.io/TerminalColors/index.html#styledText>`_
      applied to the log level label in the formatted output.
      Override in a subclass to customize.
    */
    proc styleForLogLevel(level: LogLevel): styledText {
      if level == LogLevel.INFO {
        return style().fg(TerminalColors.green());
      } else if level == LogLevel.DEBUG {
        return style().fg(TerminalColors.blue());
      } else if level == LogLevel.WARNING {
        return style().fg(TerminalColors.yellow());
      } else if level == LogLevel.ERROR {
        return style().fg(TerminalColors.red());
      } else {
        return style();
      }
    }
  }

  /*
    A :type:`LogFormat` that produces JSON object strings.

    Each call to :proc:`~LogFormat.format` returns a single-line JSON object
    containing all log fields. String values are escaped for safe JSON output.
    Pair with :type:`JsonStream` to write a complete JSON log file.

    .. code-block:: chapel

      var log = new Log.logger("app",
                                   stream=new Log.JsonStream("app.json"),
                                   format=new Log.JsonFormat());

  */
  class JsonFormat: LogFormat {
    @chpldoc.nodoc
    proc init() {
      super.init('{"timestamp":"%T%","level":"%LL%",'+
                 '"module":"%M%","routine":"%R%","line":"%N%",'+
                 '"logger":"%NAME%","message":"%m%"}');
    }
    /**/
    override proc format(timestamp: dateTime, level: LogLevel,
                moduleName: string, routineName: string, lineNumber: int,
                loggerName: string, message: string): string {
      const escape = proc(s: string): string {
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
      };
      const formattedMessage = escape(message);
      const formattedModule = escape(moduleName);
      const formattedRoutine = escape(routineName);
      const formattedName = escape(loggerName);
      try {
        return formatString([
          "T" => timestamp:string,
          "LL" => level.formatted(),
          "M" => formattedModule,
          "R" => formattedRoutine,
          "N" => lineNumber:string,
          "NAME" => formattedName,
          "m" => formattedMessage
        ]);
      } catch e {
        return "{\"error\": \"LogFormat error: '" + e.message() +
               "' while formatting message: " + formattedMessage + "\"}";
      }
    }
  }

}
