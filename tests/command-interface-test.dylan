module: command-interface-test
synopsis: Various tests for the CLI.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file LICENSE

define suite command-interface-test-suite()
  test command-tokenizer-test;
end;

run-test-application(command-interface-test-suite);
