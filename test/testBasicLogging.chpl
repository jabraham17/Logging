use UnitTest;
import Logging;
import Logging.{MN, RN, LN};

class MemoryLogStream: Logging.LogStream {
  var messages: string;
  override proc write(message: string) {
    messages += message + "\n";
  }
  override proc flush() { }
}

proc testInfoSimple(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.info("message");
  test.assertTrue(stream.messages.contains("[info]"));
  test.assertTrue(stream.messages.contains("message"));
}

proc testInfoMultiArg(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.info("count: ", 42);
  test.assertTrue(stream.messages.contains("count: 42"));
}

proc testInfoWithSourceLocation(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.info(MN(), RN(), LN(), "located");
  test.assertTrue(stream.messages.contains("located"));
  test.assertTrue(stream.messages.contains("testBasicLogging"));
  test.assertTrue(stream.messages.contains("testInfoWithSourceLocation"));
}

proc testInfoWithSourceLocationMultiArg(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.info(MN(), RN(), LN(), "count: ", 42);
  test.assertTrue(stream.messages.contains("count: 42"));
  test.assertTrue(stream.messages.contains("testBasicLogging"));
}

proc testInfof(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.infof("hello %s %i", "world", 42);
  test.assertTrue(stream.messages.contains("hello world 42"));
}

proc testInfofWithSourceLocation(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.infof(MN(), RN(), LN(), "val=%i,val2=%s", 7, "test");
  test.assertTrue(stream.messages.contains("val=7"));
  test.assertTrue(stream.messages.contains("val2=test"));
  test.assertTrue(stream.messages.contains("testInfofWithSourceLocation"));
}

proc testDebugSimple(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               logLevel=Logging.LogLevel.DEBUG,
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.debug("dbg");
  test.assertTrue(stream.messages.contains("[debug]"));
  test.assertTrue(stream.messages.contains("dbg"));
}

proc testDebugMultiArg(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               logLevel=Logging.LogLevel.DEBUG,
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.debug("x=", 10);
  test.assertTrue(stream.messages.contains("x=10"));
}

proc testDebugWithSourceLocation(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               logLevel=Logging.LogLevel.DEBUG,
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.debug(MN(), RN(), LN(), "dbg located");
  test.assertTrue(stream.messages.contains("dbg located"));
  test.assertTrue(stream.messages.contains("testBasicLogging"));
}

proc testDebugWithSourceLocationMultiArg(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               logLevel=Logging.LogLevel.DEBUG,
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.debug(MN(), RN(), LN(), "x=", 10);
  test.assertTrue(stream.messages.contains("x=10"));
  test.assertTrue(stream.messages.contains("testBasicLogging"));
}

proc testDebugf(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               logLevel=Logging.LogLevel.DEBUG,
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.debugf("val=%i,val2=%s", 99, "debug");
  test.assertTrue(stream.messages.contains("val=99"));
  test.assertTrue(stream.messages.contains("val2=debug"));
}

proc testDebugfWithSourceLocation(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               logLevel=Logging.LogLevel.DEBUG,
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.debugf(MN(), RN(), LN(), "v=%i,v2=%s", 5, "test");
  test.assertTrue(stream.messages.contains("v=5"));
  test.assertTrue(stream.messages.contains("v2=test"));
  test.assertTrue(stream.messages.contains("testBasicLogging"));
}

proc testWarnSimple(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.warn("warning msg");
  test.assertTrue(stream.messages.contains("[warning]"));
  test.assertTrue(stream.messages.contains("warning msg"));
}

proc testWarnMultiArg(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.warn("temp: ", 100, " degrees");
  test.assertTrue(stream.messages.contains("temp: 100 degrees"));
}

proc testWarnWithSourceLocation(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.warn(MN(), RN(), LN(), "warn located");
  test.assertTrue(stream.messages.contains("warn located"));
  test.assertTrue(stream.messages.contains("testBasicLogging"));
}

proc testWarnWithSourceLocationMultiArg(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.warn(MN(), RN(), LN(), "temp: ", 100);
  test.assertTrue(stream.messages.contains("temp: 100"));
  test.assertTrue(stream.messages.contains("testBasicLogging"));
}

proc testWarnf(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.warnf("disk at %i %s", 90, "percent");
  test.assertTrue(stream.messages.contains("disk at 90 percent"));
}

proc testWarnfWithSourceLocation(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.warnf(MN(), RN(), LN(), "disk=%i%s", 90, "%");
  test.assertTrue(stream.messages.contains("disk=90%"));
  test.assertTrue(stream.messages.contains("testBasicLogging"));
}

proc testErrorSimple(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.error("err msg");
  test.assertTrue(stream.messages.contains("[error]"));
  test.assertTrue(stream.messages.contains("err msg"));
}

proc testErrorMultiArg(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.error("code: ", 500);
  test.assertTrue(stream.messages.contains("code: 500"));
}

proc testErrorWithSourceLocation(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.error(MN(), RN(), LN(), "err located");
  test.assertTrue(stream.messages.contains("err located"));
  test.assertTrue(stream.messages.contains("testBasicLogging"));
}

proc testErrorWithSourceLocationMultiArg(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.error(MN(), RN(), LN(), "code: ", 500);
  test.assertTrue(stream.messages.contains("code: 500"));
  test.assertTrue(stream.messages.contains("testBasicLogging"));
}

proc testErrorf(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.errorf("failed: %s %n", "timeout", 10);
  test.assertTrue(stream.messages.contains("failed: timeout 10"));
}

proc testErrorfWithSourceLocation(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.errorf(MN(), RN(), LN(), "err=%s,other=%n", "bad", 2);
  test.assertTrue(stream.messages.contains("err=bad"));
  test.assertTrue(stream.messages.contains("other=2"));
  test.assertTrue(stream.messages.contains("testBasicLogging"));
}

proc testLogLevelFiltering_InfoLevel(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               logLevel=Logging.LogLevel.INFO,
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.info("info msg");
  log.warn("warn msg");
  log.error("error msg");
  log.debug("debug msg");
  test.assertTrue(stream.messages.contains("info msg"));
  test.assertTrue(stream.messages.contains("warn msg"));
  test.assertTrue(stream.messages.contains("error msg"));
  test.assertFalse(stream.messages.contains("debug msg"));
}

proc testLogLevelFiltering_ErrorLevel(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               logLevel=Logging.LogLevel.ERROR,
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.info("info msg");
  log.warn("warn msg");
  log.error("error msg");
  log.debug("debug msg");
  test.assertFalse(stream.messages.contains("info msg"));
  test.assertFalse(stream.messages.contains("warn msg"));
  test.assertTrue(stream.messages.contains("error msg"));
  test.assertFalse(stream.messages.contains("debug msg"));
}

proc testLogLevelFiltering_DebugLevel(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               logLevel=Logging.LogLevel.DEBUG,
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.info("info msg");
  log.warn("warn msg");
  log.error("error msg");
  log.debug("debug msg");
  test.assertTrue(stream.messages.contains("info msg"));
  test.assertTrue(stream.messages.contains("warn msg"));
  test.assertTrue(stream.messages.contains("error msg"));
  test.assertTrue(stream.messages.contains("debug msg"));
}

proc testLogLevelFiltering_WarningLevel(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               logLevel=Logging.LogLevel.WARNING,
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.info("info msg");
  log.warn("warn msg");
  log.error("error msg");
  log.debug("debug msg");
  test.assertFalse(stream.messages.contains("info msg"));
  test.assertTrue(stream.messages.contains("warn msg"));
  test.assertTrue(stream.messages.contains("error msg"));
  test.assertFalse(stream.messages.contains("debug msg"));
}

proc testLogLevelFiltering_NoneLevel(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               logLevel=Logging.LogLevel.NONE,
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.info("info msg");
  log.warn("warn msg");
  log.error("error msg");
  log.debug("debug msg");
  test.assertEqual(stream.messages, "");
}

proc testLoggerName(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("myTestLogger",
                               format=new Logging.LogFormat("%NAME% %m%"),
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.info("hello");
  test.assertTrue(stream.messages.contains("myTestLogger"));
  test.assertTrue(stream.messages.contains("hello"));
}

UnitTest.main();
