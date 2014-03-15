module: command-interface-test

define command-root $integration-root;

define variable *integration-progress* :: <symbol> = #"init";

define command simple one ($integration-root)
  simple parameter alpha;
  implementation
    begin
      *integration-progress* := #"one";
      check-equal("Value of alpha", "alpha-value", alpha);
    end;
end;

define command simple two ($integration-root)
  named parameter alpha;
  named parameter beta;
  implementation
    begin
      *integration-progress* := #"two";
      check-equal("Value of alpha", "alpha-value", alpha);
      check-equal("Value of beta",  "beta-value", beta);
    end;
end;

define command simple three ($integration-root)
  simple parameter alpha;
  simple parameter beta;
  implementation
    begin
      *integration-progress* := #"three";
      check-equal("Value of alpha", "alpha-value", alpha);
      check-equal("Value of beta",  "beta-value", beta);
    end;
end;

define test command-integration-test()  
end;
