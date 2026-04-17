import Log;
import Log.{MN, RN, LN};
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

  log.info("Log an int: ", 42);
  log.info("Log a string: ", "hello");
  log.info("Log a record: ", new myRecord(5, "hi"));

  log.info(MN(), RN(), LN(), "Info log with line info");
  log.error(MN(), RN(), LN(), "Error log with line info");
  log.debug(MN(), RN(), LN(), "Debug log with line info");
  log.warn(MN(), RN(), LN(), "Warning log with line info");
}

proc main() {
  var log = new Log.logger("my log");
  printLogs(log);

  var strm = new Log.StderrStream();
  var fmt = new Log.LogFormat("%NAME% - %LL%: %m%");
  log = new Log.logger("my log", stream=strm, format=fmt);
  printLogs(log);

  class MyCustomFormat: Log.LogFormat {
    proc init(args...) {
      super.init((...args));
    }
    override proc styleForLogName(level: Log.LogLevel): styledText {
      select level {
        when Log.LogLevel.INFO do
          return style().bold();
        when Log.LogLevel.ERROR do
          return style().bold().fg(TerminalColors.red());
        when Log.LogLevel.DEBUG do
          return style().bold().fg(TerminalColors.blue());
        when Log.LogLevel.WARNING do
          return style().bold().fg(TerminalColors.yellow());
      }
      return style();
    }
  }
  log = new Log.logger("my log",
                           logLevelEnvVar="MY_LOG_LEVEL",
                           stream=new Log.StderrStream(),
                           format=new MyCustomFormat("%NAME%: %m%"));
  printLogs(log);

  var jsonLog = new Log.logger("json log",
                            stream=new Log.JsonStream("log.json"),
                            format=new Log.JsonFormat());
  printLogs(jsonLog);
}
