import Logging;
import Logging.{MN, RN, LN};
import TerminalColors;
import TerminalColors.{styledText, style};

record myRecord {
  var x: int;
  var y: string;
}

proc printLogs(log) {
  log.info("This is an info message");
  log.error("This is an error message");
  log.debug("This is a debug message");
  log.warn("This is a warning message");

  log.info("Logging an int: ", 42);
  log.info("Logging a string: ", "hello");
  log.info("Logging a record: ", new myRecord(5, "hi"));

  log.info(MN(), RN(), LN(), "Info log with line info");
  log.error(MN(), RN(), LN(), "Error log with line info");
  log.debug(MN(), RN(), LN(), "Debug log with line info");
  log.warn(MN(), RN(), LN(), "Warning log with line info");
}

proc main() {
  var log = new Logging.logger("my log");
  printLogs(log);

  var strm = new Logging.LogStderrStream();
  var fmt = new Logging.LogFormat("%NAME% - %LL%: %m%");
  log = new Logging.logger("my log", stream=strm, format=fmt);
  printLogs(log);

  class MyCustomFormat: Logging.LogFormat {
    proc init(args...) {
      super.init((...args));
    }
    override proc styleForLogName(level: Logging.LogLevel): styledText {
      select level {
        when Logging.LogLevel.INFO do
          return style().bold();
        when Logging.LogLevel.ERROR do
          return style().bold().fg(TerminalColors.red());
        when Logging.LogLevel.DEBUG do
          return style().bold().fg(TerminalColors.blue());
        when Logging.LogLevel.WARNING do
          return style().bold().fg(TerminalColors.yellow());
      }
      return style();
    }
  }
  log = new Logging.logger("my log",
                           logLevelEnvVar="MY_LOG_LEVEL",
                           stream=new Logging.LogStderrStream(),
                           format=new MyCustomFormat("%NAME%: %m%"));
  printLogs(log);

  var jsonLog = new Logging.logger("json log",
                            stream=new Logging.JsonLogStream("log.json"),
                            format=new Logging.JsonLogFormat());
  printLogs(jsonLog);
}
