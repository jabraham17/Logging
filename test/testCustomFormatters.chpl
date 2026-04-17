use UnitTest;
import Log;
import Log.{MN, RN, LN};
import TerminalColors;
import TerminalColors.{styledText, style};
use IO;
import Time;

class MemoryLogStream: Log.LogStream {
  var messages: string;
  override proc write(message: string) {
    messages += message + "\n";
  }
  override proc flush() { }
}

proc readLogFile(filename: string): string throws {
  var f = open(filename, ioMode.r);
  var r = f.reader(locking=false);
  var content: string;
  r.readAll(content);
  r.close();
  f.close();
  return content;
}


class CustomStyleFormat: Log.LogFormat {
  proc init(formatString: string = "%T% [%LL%] %NAME% %m%") {
    super.init(formatString);
  }
  override proc styleForLogLevel(level: Log.LogLevel): styledText {
    return style().fg(TerminalColors.magenta()).bold();
  }
  override proc styleForLogName(level: Log.LogLevel): styledText {
    return style().fg(TerminalColors.cyan()).italic();
  }
  override proc styleForTimestamp(level: Log.LogLevel): styledText {
    return style().fg(TerminalColors.green()).dim();
  }
}

proc testCustomStyle(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Log.logger("test",
                               colorMode=Log.ColorMode.ALWAYS,
                               stream=stream,
                               format=new CustomStyleFormat());
  const time = Time.dateTime.now();
  log.info("hello");

  var timeStr = time:string;
  // chop off the seconds so we can fuzzy match
  var lastColon = timeStr.rfind(":"):int;
  timeStr = timeStr[0..lastColon];

  const expectedTimeStr = style().fg(TerminalColors.green()).dim() + timeStr;

  const expected =
    "[" + style("info").fg(TerminalColors.magenta()).bold() + "] " +
    style("test").fg(TerminalColors.cyan()).italic() + " hello";

  test.assertTrue(stream.messages.startsWith(expectedTimeStr));
  test.assertTrue(stream.messages.strip().endsWith(expected));
}


class FixedFormat: Log.LogFormat {
  proc init() {
    super.init("%m%");
  }
  @chplcheck.ignore("UnusedFormal")
  override proc format(timestamp, level, moduleName,
                       routineName, lineNumber,
                       loggerName, message: string): string {
    return "CUSTOM: " + message;
  }
}

proc testCustomFormatOverride(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Log.logger("test",
                               colorMode=Log.ColorMode.NEVER,
                               stream=stream,
                               format=new FixedFormat());
  log.info("hello");
  test.assertEqual(stream.messages.strip(), "CUSTOM: hello");
}

UnitTest.main();
