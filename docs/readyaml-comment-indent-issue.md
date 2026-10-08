# `readyaml` drops leading indentation from any line with a trailing comment

**Component:** `toolbox/readyaml.m`, `removeComments`
**Version:** `main` @ cfcec2e

## Summary

`removeComments` strips the trailing comment with `strtrim`, which also removes
the line's **leading** whitespace. In a block-structured format the indentation
*is* the structure, so every line carrying a trailing comment is promoted to
indent 0 and re-parented to the document root.

```matlab
% toolbox/readyaml.m, removeComments
elseif ~inQuotes && line(j) == '#'
    lines{i} = strtrim(line(1:j-1));   % <-- also removes the indentation
    break;
end
```

## Reproduction

```yaml
options:
  include_self: true      # source == target pairs
  nested:
    depth: 2              # still two levels down
other: 1
```

```matlab
data = readyaml("repro.yaml");
keys(data)
```

Expected:

```
    "options"    "other"
```

Actual:

```
    "options"    "include_self"    "depth"    "other"
```

`data.options.include_self` errors; `data.include_self` returns `true`.

A block with no comments nests correctly, so the corruption looks arbitrary and
depends only on which lines happen to carry comments. On a real 367-line config
this turned 9 top-level keys into 26, silently — the parse succeeds, it just
describes a different document. Nothing in the output indicates that the
structure changed.

## Fix

Right-trim only:

```matlab
lines{i} = deblank(line(1:j-1));
```

`deblank` removes trailing whitespace and leaves the indentation, which is what
the subsequent `getIndentation` / `parseBlock` logic depends on. Comment-only
lines still reduce to `''` and are skipped by `parseBlock`'s empty-line branch,
so nothing else changes.

## Why the tests miss it

`yamltest/testCommentsIgnored` covers comments only on **top-level** keys:

```yaml
# This is a comment
name: Test  # inline comment
# Another comment
value: 123
```

At indent 0, `strtrim` and `deblank` are indistinguishable. The bug needs an
indented line with a trailing comment.

Suggested regression test (`tests/yamltest.m`):

```matlab
function testTrailingCommentKeepsIndentation(testCase)
    yamlText = sprintf(['options:\n' ...
        '  include_self: true      # source == target pairs\n' ...
        '  nested:\n' ...
        '    depth: 2              # still two levels down\n' ...
        'other: 1']);

    filename = fullfile(pwd, 'test.yaml');
    writelines(yamlText, filename);

    data = readyaml(filename);

    testCase.verifyEqual(sort(keys(data)), ["options", "other"], ...
        'Commented lines must not become top-level keys');
    testCase.verifyTrue(data.options.include_self);
    testCase.verifyEqual(data.options.nested.depth, 2);
    testCase.verifyFalse(iskey(data, "include_self"));
    testCase.verifyFalse(iskey(data, "depth"));
end
```

## Note on a related edge case

`removeComments` treats any unquoted `#` as the start of a comment. YAML starts a
comment only at the beginning of a line or after whitespace, so `key: a#b`
should keep `a#b` but currently yields `a`. Not the subject of this report, but
the same function, and a one-condition change:

```matlab
elseif ~inQuotes && line(j) == '#' && (j == 1 || isspace(line(j-1)))
```
