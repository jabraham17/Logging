use UnitTest;
import Log;
import Log.{MN, RN, LN};

class MemoryLogStream: Log.LogStream {
  var messages: string;
  override proc write(message: string) {
    messages += message + "\n";
  }
  override proc flush() { }
}

proc testDefaultFormat(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Log.logger("test",
                               stream=stream,
                               colorMode=Log.ColorMode.NEVER);
  log.info("unique_test_message");
  test.assertTrue(stream.messages.contains("[info]"));
  test.assertTrue(stream.messages.contains("unique_test_message"));
}

proc testCustomFormatMessageOnly(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Log.logger("test",
                               stream=stream,
                               format=new Log.LogFormat("%m%"));
  log.info("just the message");
  test.assertEqual(stream.messages.strip(), "just the message");
}

proc testCustomFormatNameAndMessage(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Log.logger("myLog", stream=stream,
                               format=new Log.LogFormat("%NAME%: %m%"));
  log.error("hello");
  test.assertEqual(stream.messages.strip(), "myLog: hello");
}

proc testCustomFormatLevelAndMessage(test: borrowed Test) throws {
  var stream = new shared MemoryLogStream();
  var log = new Log.logger("test", stream=stream,
                               format=new Log.LogFormat("[%LL%] %m%"));
  log.warn("hello");
  test.assertEqual(stream.messages.strip(), "[warning] hello");
}

UnitTest.main();
