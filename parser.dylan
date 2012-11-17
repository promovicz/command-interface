module: cli

define class <cli-parse-error> (<simple-error>)
  slot error-parser :: <cli-parser>,
    init-keyword: parser:;
  slot error-token :: <cli-token>,
    init-keyword: token:;
end class;

define class <cli-ambiguous-error> (<cli-parse-error>)
end class;

define class <cli-unknown-error> (<cli-parse-error>)
end class;


define class <cli-parser> (<object>)
  slot parser-source :: <cli-source>,
    init-keyword: source:;

  slot parser-current-node :: <cli-node>,
    init-keyword: initial-node:;

  slot parser-handlers :: <list> = #();

  slot parser-tokens :: <list> = #();
  slot parser-nodes :: <list> = #();

  slot parser-parameters :: <table> = make(<object-table>);
end class;

define method parser-execute(parser :: <cli-parser>)
 => ();
  let handlers = reverse(parser-handlers(parser));
  if(size(handlers) > 0)
    let hn = element(handlers, 0);
    hn(parser);
  end;
end method;

define method parser-parse(parser :: <cli-parser>, tokens :: <sequence>)
 => ();
  for(token in tokens)
    if(token-string(token) = "?")
      let completions = parser-complete(parser, #f);
      format-out("completions: %=\n", completions);
    else
      parser-advance(parser, token);
    end
  end for;
end method;

define method parser-get-parameter(parser :: <cli-parser>, name :: <symbol>)
 => (value :: <object>);
  element(parser-parameters(parser), name, default: #f);
end method;

define method parser-push-param(parser :: <cli-parser>, param :: <cli-parameter>, value :: <object>)
 => (value :: <object>);
  if(node-repeatable?(param))
    element(parser-parameters(parser), parameter-name(param)) := 
      add(element(parser-parameters(parser), parameter-name(param), default: #()), value);
  else
    element(parser-parameters(parser), parameter-name(param)) := value;
  end;
  value;
end method;

define method parser-push-handler(parser :: <cli-parser>, h :: <function>)
 => ();
  parser-handlers(parser) := add(parser-handlers(parser), h);
end method;

define method parser-push-node(parser :: <cli-parser>, token :: <cli-token>, node :: <cli-node>)
 => (node :: <cli-node>);
  parser-current-node(parser) := node;
  parser-nodes(parser) := add(parser-nodes(parser), node);
  parser-tokens(parser) := add(parser-tokens(parser), token);
  node;
end method;



define method parser-advance(parser :: <cli-parser>, token :: <cli-token>)
  let current-node = parser-current-node(parser);
  // filter out non-acceptable nodes
  let acceptable = choose(rcurry(node-acceptable?, parser),
                          node-successors(current-node));
  // find all matches
  let matches = #();
  for(successor in acceptable)
    if(node-match(successor, parser, token))
      matches := add(matches, successor);
    end
  end for;
  // act on matches
  select(matches.size)
    1 =>
      begin
        let succ = element(matches, 0);
        node-accept(succ, parser, token);
        parser-push-node(parser, token, succ);
      end;
    0 =>
      signal(make(<cli-unknown-error>,
                  format-string: "Unknown token \"%s\":\n",
                  format-arguments: vector(token-string(token)),
                  parser: parser,
                  token: token));
    otherwise =>
      signal(make(<cli-ambiguous-error>,
                  format-string: "Ambiguous token \"%s\":\n",
                  format-arguments: vector(token-string(token)),
                  parser: parser,
                  token: token));
  end select;

end method;

define method parser-complete(parser :: <cli-parser>, token :: false-or(<cli-token>))
 => (completions :: <sequence>);
  let current-node = parser-current-node(parser);

  // get all non-hidden successors
  let acceptable = choose(predicate-not(node-hidden?), node-successors(current-node));

  // filter out non-acceptable nodes
  acceptable := choose(rcurry(node-acceptable?, parser), acceptable);

  // filter with token if available
  if(token)
    acceptable := choose(rcurry(node-match, parser, token), acceptable);
  end;

  // collect completions from each node
  let completions-by-node = map(rcurry(node-complete, parser, token), acceptable);

  // concatenate and return
  if(empty?(completions-by-node))
    #()
  else
    apply(concatenate, completions-by-node);
  end
end method;
