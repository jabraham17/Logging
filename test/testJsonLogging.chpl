use UnitTest;
import Log;
import Log.{MN, RN, LN};
use IO;
use List;
use Map;
use JSON;

record logData {
  var logs: list(map(string, string));
}

proc readLogFile(filename: string): logData throws {
  var f = open(filename, ioMode.r);
  var r = f.reader(deserializer=new jsonDeserializer());
  return r.read(logData);
}

proc makeJsonLogger(name: string, filename: string): Log.logger {
  return new Log.logger(name,
                            logLevel=Log.LogLevel.INFO,
                            colorMode=Log.ColorMode.NEVER,
                            stream=new Log.JsonStream(filename),
                            format=new Log.JsonFormat());
}

proc testJsonSingleEntry(test: borrowed Test) throws {
  const filename = "/tmp/test_json_single.json";
  {
    var log = makeJsonLogger("testLogger", filename);
    log.info("hello");
  }
  var content = readLogFile(filename);
  test.assertEqual(content.logs.size, 1);
  var entry = content.logs[0];
  test.assertEqual(entry["message"], "hello");
  test.assertEqual(entry["logger"], "testLogger");
}

proc testJsonMultipleEntries(test: borrowed Test) throws {
  const filename = "/tmp/test_json_multi.json";
  {
    var log = makeJsonLogger("testLogger", filename);
    log.info("msg1");
    log.warn("msg2");
    log.error("msg3");
    log.debug("msg4"); // should not be logged due to log level filtering
  }
  var content = readLogFile(filename);
  test.assertEqual(content.logs.size, 3);
  test.assertEqual(content.logs[0]["message"], "msg1");
  test.assertEqual(content.logs[0]["level"], "info");
  test.assertEqual(content.logs[1]["message"], "msg2");
  test.assertEqual(content.logs[1]["level"], "warning");
  test.assertEqual(content.logs[2]["message"], "msg3");
  test.assertEqual(content.logs[2]["level"], "error");
}

proc testJsonEscaping(test: borrowed Test) throws {
  const filename = "/tmp/test_json_escape.json";
  {
    var log = makeJsonLogger("testLogger", filename);
    log.info("say \"hi\" and \\path");
  }
  var content = readLogFile(filename);
  test.assertEqual(content.logs.size, 1);
  var entry = content.logs[0];
  test.assertEqual(entry["message"], "say \"hi\" and \\path");
}

proc testJsonSourceLocation(test: borrowed Test) throws {
  const filename = "/tmp/test_json_sourceloc.json";
  var m: string, r: string, l: string;
  {
    var log = makeJsonLogger("testLogger", filename);
    log.info(MN(), RN(), LN(), "located"); m = MN(); r = RN(); l = LN():string;
  }
  var content = readLogFile(filename);
  test.assertEqual(content.logs.size, 1);
  var entry = content.logs[0];
  test.assertEqual(entry["message"], "located");
  test.assertEqual(entry["module"], m);
  test.assertEqual(entry["routine"], r);
  test.assertEqual(entry["line"], l);

}

proc testJsonFormatf(test: borrowed Test) throws {
  const filename = "/tmp/test_json_formatf.json";
  {
    var log = makeJsonLogger("testLogger", filename);
    log.infof("count=\"%s\"", "mystr\\n");
  }
  var content = readLogFile(filename);
  test.assertEqual(content.logs.size, 1);
  var entry = content.logs[0];
  test.assertEqual(entry["message"], "count=\"mystr\\n\"");
}

UnitTest.main();
