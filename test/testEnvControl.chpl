use UnitTest;
import Log;

proc setEnv(name: string, value: string) throws {
  use CTypes;
  extern proc setenv(name: c_ptrConst(c_char),
                     value: c_ptrConst(c_char), overwrite: c_int): c_int;
  extern proc unsetenv(name: c_ptrConst(c_char)): c_int;
  if value == "" {
    unsetenv(name.c_str());
  } else {
    setenv(name.c_str(), value.c_str(), 1);
  }
}

proc testEnvVarName(test: borrowed Test) throws {
  use Log.LogLevel;
  test.assertEqual(LogLevel.makeEnvName("myApp"), "MYAPP_LOG_LEVEL");
  test.assertEqual(LogLevel.makeEnvName("my-service"), "MY_SERVICE_LOG_LEVEL");
  test.assertEqual(LogLevel.makeEnvName("my app"), "MY_APP_LOG_LEVEL");
  test.assertEqual(LogLevel.makeEnvName("app2"), "APP2_LOG_LEVEL");
  test.assertEqual(LogLevel.makeEnvName("MY_APP"), "MY_APP_LOG_LEVEL");
}

proc testGetLevelFromEnv(test: borrowed Test) throws {
  use Log.LogLevel;
  {
    var log = new Log.logger("test", logLevel=LogLevel.DEBUG);
    // check the log level is correct when env var is not set
    test.assertEqual(log.logLevel, LogLevel.DEBUG);
  }
  {
    defer setEnv("TEST_LOG_LEVEL", "");
    setEnv("TEST_LOG_LEVEL", "error");
    var log = new Log.logger("test");
    test.assertEqual(log.logLevel, LogLevel.ERROR);
    setEnv("TEST_LOG_LEVEL", "DEBUG");
    log = new Log.logger("test");
    test.assertEqual(log.logLevel, LogLevel.DEBUG);
  }
  {
    defer setEnv("TEST_LOG_LEVEL", "");
    setEnv("TEST_LOG_LEVEL", "invalid");
    var log = new Log.logger("test", logLevel=LogLevel.WARNING);
    // should fall back to default log level if env var value is invalid
    test.assertEqual(log.logLevel, LogLevel.WARNING);
  }
  {
    // custom env var
    defer setEnv("MY_LOG_LEVEL", "");
    setEnv("MY_LOG_LEVEL", "info");
    var log = new Log.logger("test", logLevelEnvVar="MY_LOG_LEVEL",
                                         logLevel=LogLevel.DEBUG);
    test.assertEqual(log.logLevel, LogLevel.INFO);
  }

}

UnitTest.main();
