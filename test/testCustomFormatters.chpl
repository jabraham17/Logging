use UnitTest;
import Logging;
import Logging.{MN, RN, LN};
import TerminalColors;
import TerminalColors.{styledText, style};
use IO;
import Time;

class MemoryLogStream: Logging.LogStream {
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


class CustomStyleFormat: Logging.LogFormat {
  proc init(formatString: string = "%T% [%LL%] %NAME% %m%") {
    super.init(formatString);
  }
  override proc styleForLogLevel(level: Logging.LogLevel): styledText {
    return style().fg(TerminalColors.magenta()).bold();
  }
  override proc styleForLogName(level: Logging.LogLevel): styledText {
    return style().fg(TerminalColors.cyan()).italic();
  }
  override proc styleForTimestamp(level: Logging.LogLevel): styledText {
    return style().fg(TerminalColors.green()).dim();
  }
}

proc testCustomStyle(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               colorMode=Logging.ColorMode.ALWAYS,
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


class FixedFormat: Logging.LogFormat {
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
  var log = new Logging.logger("test",
                               colorMode=Logging.ColorMode.NEVER,
                               stream=stream,
                               format=new FixedFormat());
  log.info("hello");
  test.assertEqual(stream.messages.strip(), "CUSTOM: hello");
}

UnitTest.main();
