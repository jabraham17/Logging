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

proc testDefaultFormat(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               stream=stream,
                               colorMode=Logging.ColorMode.NEVER);
  log.info("unique_test_message");
  test.assertTrue(stream.messages.contains("[info]"));
  test.assertTrue(stream.messages.contains("unique_test_message"));
}

proc testCustomFormatMessageOnly(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test",
                               stream=stream,
                               format=new Logging.LogFormat("%m%"));
  log.info("just the message");
  test.assertEqual(stream.messages.strip(), "just the message");
}

proc testCustomFormatNameAndMessage(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("myLog", stream=stream,
                               format=new Logging.LogFormat("%NAME%: %m%"));
  log.error("hello");
  test.assertEqual(stream.messages.strip(), "myLog: hello");
}

proc testCustomFormatLevelAndMessage(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Logging.logger("test", stream=stream,
                               format=new Logging.LogFormat("[%LL%] %m%"));
  log.warn("hello");
  test.assertEqual(stream.messages.strip(), "[warning] hello");
}

UnitTest.main();
