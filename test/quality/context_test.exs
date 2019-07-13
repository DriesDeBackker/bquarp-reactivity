defmodule Test.BQuarp.ContextTest do
  use ExUnit.Case
  alias Reactivity.Quality.Guarantee
  alias Reactivity.Quality.Context

  # @tag: disabled
  test "Combine single context in case of :t (1)" do
    c = 5
    cs = [c]
    combined_c = Context.combine(cs, :t)
    assert(combined_c == 5)
  end

  # @tag: disabled
  test "Combine single context in case of :t (2)" do
    c = {2, 4}
    cs = [c]
    combined_c = Context.combine(cs, :t)
    assert(combined_c == {2, 4})
  end

  # @tag :disabled
  test "Combine contexts in case of :t (1)" do
    c1 = 5
    c2 = {2, 4}
    cs = [c1, c2]
    combined_c = Context.combine(cs, :t)
    assert(combined_c == {2, 5})
  end

  # @tag :disabled
  test "Combine contexts in case of :t (2)" do
    c1 = 5
    c2 = 5
    cs = [c1, c2]
    combined_c = Context.combine(cs, :t)
    assert(combined_c == 5)
  end

  # @tag :disabled
  test "Combine contexts in case of :t (3)" do
    c1 = {1, 3}
    c2 = {2, 4}
    cs = [c1, c2]
    combined_c = Context.combine(cs, :t)
    assert(combined_c == {1, 4})
  end

  # @tag :disabled
  test "Combine contexts in case of :t (4)" do
    c1 = {1, 3}
    c2 = {2, 4}
    c3 = 5
    cs = [c1, c2, c3]
    combined_c = Context.combine(cs, :t)
    assert(combined_c == {1, 5})
  end

  # @tag :disabled
  test "Combine contexts in case of :t (5)" do
    c1 = 3
    c2 = 4
    c3 = 5
    cs = [c1, c2, c3]
    combined_c = Context.combine(cs, :t)
    assert(combined_c == {3, 5})
  end

  # @tag :disabled
  test "Combine single context in case of :g (1)" do
    c = [{:s1, 5}]
    cs = [c]
    combined_c = Context.combine(cs, :g)
    assert(combined_c == [{:s1, 5}])
  end

  # @tag :disabled
  test "Combine single context in case of :g (2)" do
    c = [{:s1, 5}, {:s2, 7}]
    cs = [c]
    combined_c = Context.combine(cs, :g)
    assert(combined_c == [{:s1, 5}, {:s2, 7}])
  end

  # @tag :disabled
  test "Combine contexts in case of :g (1)" do
    c1 = [{:s1, 5}]
    c2 = [{:s2, 7}]
    cs = [c1, c2]
    combined_c = Context.combine(cs, :g)
    assert(combined_c == [{:s1, 5}, {:s2, 7}])
  end

  # @tag :disabled
  test "Combine contexts in case of :g (2)" do
    c1 = [{:s1, 5}]
    c2 = [{:s1, 5}, {:s2, 7}]
    cs = [c1, c2]
    combined_c = Context.combine(cs, :g)
    assert(combined_c == [{:s1, 5}, {:s2, 7}])
  end

  # @tag :disabled
  test "Combine contexts in case of :g (3)" do
    c1 = [{:s1, 5}]
    c2 = [{:s1, 3}, {:s2, 7}]
    cs = [c1, c2]
    combined_c = Context.combine(cs, :g)
    assert(combined_c == [{:s1, {3, 5}}, {:s2, 7}])
  end

  # @tag :disabled
  test "Combine contexts in case of :g (4)" do
    c1 = [{:s1, {3, 5}}]
    c2 = [{:s1, 2}, {:s2, 7}]
    cs = [c1, c2]
    combined_c = Context.combine(cs, :g)
    assert(combined_c == [{:s1, {2, 5}}, {:s2, 7}])
  end

  # @tag :disabled
  test "Combine contexts in case of :g (5)" do
    c1 = [{:s1, {3, 5}}, {:s2, 4}]
    c2 = [{:s1, 2}, {:s2, 7}]
    cs = [c1, c2]
    combined_c = Context.combine(cs, :g)
    assert(combined_c == [{:s1, {2, 5}}, {:s2, {4, 7}}])
  end

  # @tag :disabled
  test "Combine contexts in case of :g (6)" do
    c1 = [{:s1, {3, 5}}, {:s2, 4}]
    c2 = [{:s2, 7}, {:s1, 2}]
    cs = [c1, c2]
    combined_c = Context.combine(cs, :g)
    assert(combined_c == [{:s1, {2, 5}}, {:s2, {4, 7}}])
  end

  # @tag :disabled
  test "Combine contexts in case of :g (7)" do
    c1 = [{:s1, {3, 5}}, {:s2, 4}]
    c2 = [{:s2, 7}, {:s1, 2}]
    c3 = [{:s3, 4}, {:s2, {3, 5}}]
    cs = [c1, c2, c3]
    combined_c = Context.combine(cs, :g)
    assert(combined_c == [{:s1, {2, 5}}, {:s2, {3, 7}}, {:s3, 4}])
  end

  # @tag :disabled
  test "Combine contexts in case of :g (8)" do
    c1 = [{{:bob@MSI, :temperature1}, {3, 5}}, {{:bob@MSI, :temperature2}, 4}]
    c2 = [{{:bob@MSI, :temperature2}, 7}, {{:bob@MSI, :temperature1}, 2}]
    cs = [c1, c2]
    combined_c = Context.combine(cs, :g)

    assert(
      combined_c == [{{:bob@MSI, :temperature1}, {2, 5}}, {{:bob@MSI, :temperature2}, {4, 7}}]
    )
  end

  # @tag :disabled
  test "Combine single context in case of :c (1)" do
    c = [{:a, 0}, {:b, 0}]
    cs = [c]
    combined_c = Context.combine(cs, :c)
    assert(combined_c == [[{:a, 0}, {:b, 0}]])
  end

  # @tag :disabled
  test "Combine single context in case of :c (2)" do
    c = [[[{:a, 0}], [{:b, 0}]], {:c, 0}]
    cs = [c]
    combined_c = Context.combine(cs, :c)
    assert(combined_c == [[[[{:a, 0}], [{:b, 0}]], {:c, 0}]])
  end

  # @tag :disabled
  test "Combine contexts in case of :c (1)" do
    c1 = [{:a, 0}, {:b, 0}]
    c2 = [{:a, 1}]
    cs = [c1, c2]
    combined_c = Context.combine(cs, :c)
    assert(combined_c == [[{:a, 0}, {:b, 0}], [{:a, 1}]])
  end

  # @tag :disabled
  test "Combine contexts in case of :c (2)" do
    c1 = [[[{:a, 0}], [{:b, 0}]], {:c, 0}]
    c2 = [{:a, 1}]
    cs = [c1, c2]
    combined_c = Context.combine(cs, :c)
    assert(combined_c == [[[[{:a, 0}], [{:b, 0}]], {:c, 0}], [{:a, 1}]])
  end

  ######################################################

  # @tag: disabled
  test "Combine context lists (1)" do
    gss = [[], []]
    css = [[], []]
    assert(Context.combine(css, gss) == [])
  end

  # @tag :disabled
  test "combine context lists (2)" do
    gss = [
      [],
      [{:t, 0}, {:g, 1}]
    ]

    css = [
      [],
      [3, [{:a, 3}, {:c, 8}]]
    ]

    assert(
      Context.combine(css, gss) ==
        [[{:a, 3}, {:c, 8}], 3]
    )
  end

  # @tag :disabled
  test "combine context lists (3)" do
    gss = [
      [{:t, 1}, {:g, 0}],
      []
    ]

    css = [
      [{4, 5}, [{:a, 3}, {:b, 2}]],
      []
    ]

    assert(
      Context.combine(css, gss) ==
        [[{:a, 3}, {:b, 2}], {4, 5}]
    )
  end

  # @tag :disabled
  test "combine context lists (4)" do
    gss = [
      [{:t, 1}, {:g, 0}],
      [{:t, 0}, {:g, 1}]
    ]

    css = [
      [{4, 5}, [{:a, 3}, {:b, 2}]],
      [3, [{:a, 3}, {:c, 8}]]
    ]

    assert(
      Context.combine(css, gss) ==
        [[{:a, 3}, {:b, 2}, {:c, 8}], {3, 5}]
    )
  end

  # @tag :disabled
  test "combine context lists (5)" do
    gss = [
      [{:t, 1}, {:g, 0}]
    ]

    css = [
      [{4, 5}, [{:a, 3}, {:b, 2}]]
    ]

    assert(
      Context.combine(css, gss) ==
        [[{:a, 3}, {:b, 2}], {4, 5}]
    )
  end

  # @tag :disabled
  test "combine context lists (6)" do
    gss = [
      [{:t, 1}, {:g, 0}],
      [{:c, 0}, {:g, 1}],
      [{:c, 0}]
    ]

    css = [
      [{4, 5}, [{:a, 3}, {:b, 2}]],
      [[{:c, 1}, {:d, 1}], [{:a, 2}, {:e, 9}]],
      [[{:c, 2}, {:d, 2}, {:f, 2}]]
    ]

    assert(
      Context.combine(css, gss) ==
        [
          [[{:c, 1}, {:d, 1}], [{:c, 2}, {:d, 2}, {:f, 2}]],
          [{:a, {2, 3}}, {:b, 2}, {:e, 9}],
          {4, 5}
        ]
    )
  end

  ##############################################################

  # @tag :disabled
  test "sufficient quality (1)" do
    gss = [
      [{:t, 1}, {:g, 0}],
      [{:t, 0}, {:g, 1}]
    ]

    css = [
      [{4, 5}, [{:a, 3}, {:b, 2}]],
      [3, [{:a, 3}, {:c, 8}]]
    ]

    combinedgs = Guarantee.combine(gss)
    combinedcs = Context.combine(css, gss)
    assert(Context.sufficient_quality?(combinedcs, combinedgs) == false)
  end

  # @tag :disabled
  test "sufficient quality (2)" do
    gss = [
      [{:t, 1}, {:g, 0}],
      [{:t, 0}, {:g, 1}]
    ]

    css = [
      [3, [{:a, 3}, {:b, 2}]],
      [3, [{:a, 3}, {:c, 8}]]
    ]

    combinedgs = Guarantee.combine(gss)
    combinedcs = Context.combine(css, gss)
    assert(Context.sufficient_quality?(combinedcs, combinedgs) == true)
  end

  # @tag :disabled
  test "sufficient quality (3)" do
    gss = [
      [{:t, 1}, {:g, 0}],
      [{:t, 0}, {:g, 1}]
    ]

    css = [
      [3, [{:a, 3}, {:b, 2}]],
      [3, [{:a, {4, 5}}, {:c, 8}]]
    ]

    combinedgs = Guarantee.combine(gss)
    combinedcs = Context.combine(css, gss)
    assert(Context.sufficient_quality?(combinedcs, combinedgs) == false)
  end

  # @tag :disabled
  test "sufficient quality (4)" do
    gss = [
      [{:t, 1}, {:g, 1}],
      [{:t, 0}, {:g, 1}]
    ]

    css = [
      [3, [{:a, 4}, {:b, 2}]],
      [3, [{:a, {4, 5}}, {:c, 8}]]
    ]

    combinedgs = Guarantee.combine(gss)
    combinedcs = Context.combine(css, gss)
    assert(Context.sufficient_quality?(combinedcs, combinedgs) == true)
  end

  # @tag :disabled
  test "sufficient quality (5)" do
    gss = [
      [{:t, 1}, {:g, 1}],
      [{:c, 0}, {:g, 1}],
      [{:c, 0}]
    ]

    css = [
      [{4, 5}, [{:a, 3}, {:b, 2}]],
      [[{:c, 1}, {:d, 1}], [{:a, 2}, {:e, 9}]],
      [[{:c, 2}, {:d, 2}, {:f, 2}]]
    ]

    combinedgs = Guarantee.combine(gss)
    combinedcs = Context.combine(css, gss)
    assert(Context.sufficient_quality?(combinedcs, combinedgs) == false)
  end

  # @tag :disabled
  test "sufficient quality (6)" do
    gss = [
      [{:t, 1}, {:g, 1}],
      [{:c, 0}, {:g, 1}],
      [{:c, 0}]
    ]

    css = [
      [{4, 5}, [{:a, 3}, {:b, 2}]],
      [[{:c, 3}, {:d, 3}], [{:a, 2}, {:e, 9}]],
      [[{:c, 2}, {:d, 2}, {:f, 2}]]
    ]

    combinedgs = Guarantee.combine(gss)
    combinedcs = Context.combine(css, gss)
    assert(Context.sufficient_quality?(combinedcs, combinedgs) == true)
  end

  # @tag :disabled
  test "sufficient quality (7)" do
    gss = [
      [{:t, 1}, {:g, 0}],
      [{:c, 0}, {:g, 1}],
      [{:c, 0}]
    ]

    css = [
      [{4, 5}, [{:a, 3}, {:b, 2}]],
      [[{:c, 3}, {:d, 3}], [{:a, 2}, {:e, 9}]],
      [[{:c, 2}, {:d, 2}, {:f, 2}]]
    ]

    combinedgs = Guarantee.combine(gss)
    combinedcs = Context.combine(css, gss)
    assert(Context.sufficient_quality?(combinedcs, combinedgs) == false)
  end

  #####################################################################

  # @tag :disabled
  test "Penalty of an intermediate context in glitch freedom :g (1)" do
    i = [{:s1, {1, 3}}, {:s2, 5}]
    assert Context.penalty(i, :g) == 2
  end

  # @tag :disabled
  test "Penalty of an intermediate context in glitch freedom :g (2)" do
    i = [{:s1, {1, 3}}, {:s2, {2, 5}}]
    assert Context.penalty(i, :g) == 3
  end

  # @tag :disabled
  test "Penalty of an intermediate context in glitch freedom :g (3)" do
    i = [{:s1, {1, 3}}, {:s2, {2, 5}}, {:s3, 5}]
    assert Context.penalty(i, :g) == 3
  end

  # @tag :disabled
  test "Penalty of an intermediate context in time-synch :t (1)" do
    i = 5
    assert Context.penalty(i, :t) == 0
  end

  # @tag :disabled
  test "Penalty of an intermediate context in time-synch :t (2)" do
    i = {1, 5}
    assert Context.penalty(i, :t) == 4
  end

  # @tag :disabled
  test "Penalty of an intermediate context under causality :c (1)" do
    i = [[{:a, 1}], [{:b, 4}]]
    assert Context.penalty(i, :c) == 0
  end

  # @tag :disabled
  test "Penalty of an intermediate context under causality :c (2)" do
    i = [[{:a, 1}], [{:a, 4}]]
    assert Context.penalty(i, :c) == 0
  end

  # @tag :disabled
  test "Penalty of an intermediate context under causality :c (3)" do
    i = [[{:a, 3}], [{:a, 1}, {:b, 2}]]
    assert Context.penalty(i, :c) == 0
  end

  # @tag :disabled
  test "Penalty of an intermediate context under causality :c (4)" do
    i = [[{:a, 1}], [{:a, 4}, {:b, 2}]]
    assert Context.penalty(i, :c) == 3
  end

  # @tag :disabled
  test "Penalty of an intermediate context under causality :c (5)" do
    i = [[{:a, 0}, {:b, 0}, {:c, 0}], [{:a, 2}, {:b, 2}]]
    assert Context.penalty(i, :c) == 0
  end

  # @tag :disabled
  test "Penalty of an intermediate context under causality :c (6)" do
    i = [[{:a, 3}, {:b, 3}, {:c, 3}], [{:a, 2}, {:b, 2}]]
    assert Context.penalty(i, :c) == 1
  end

  # @tag :disabled
  test "Penalty of an intermediate context under causality :c (7)" do
    i = [[{:a, 3}, {:b, 3}], [{:c, 5}, {:d, 8}]]
    assert Context.penalty(i, :c) == 0
  end

  # @tag :disabled
  test "Penalty of an intermediate context under causality :c (8)" do
    i = [[[[{:a, 0}, {:b, 0}, {:c, 0}], [{:a, 2}, {:b, 2}]], {:d, 6}], [{:a, 1}]]
    assert Context.penalty(i, :c) == 1
  end

  # @tag :disabled
  test "Penalty of an intermediate context under causality :c (9)" do
    i = [[[[{:a, 0}, {:b, 0}, {:c, 0}], [{:a, 2}, {:b, 2}]], {:d, 6}], [{:a, 0}]]
    assert Context.penalty(i, :c) == 2
  end

  # @tag :disabled
  test "Penalty of an intermediate context under causality :c (10)" do
    i = [[[[{:a, 0}, {:b, 0}, {:c, 0}], [{:a, 2}, {:b, 2}]], {:d, 6}], [{:a, 5}]]
    assert Context.penalty(i, :c) == 0
  end

  # @tag :disabled
  test "Penalty of an intermediate context under causality :c (11)" do
    i = [
      [[[{:a, 0}, {:b, 0}, {:c, 0}], [{:a, 2}, {:b, 2}]], {:d, 6}],
      [[[{:a, 1}, {:b, 1}, {:c, 1}], [{:a, 2}, {:b, 2}]], {:d, 7}]
    ]

    assert Context.penalty(i, :c) == 0
  end

  # @tag :disabled
  test "Penalty of an intermediate context under causality :c (12)" do
    i = [
      [[[{:a, 0}, {:b, 0}, {:c, 0}], [{:a, 2}, {:b, 2}]], {:d, 6}],
      [[[{:a, 1}, {:b, 1}, {:c, 1}], [{:a, 2}, {:b, 2}]], {:d, 7}, {:e, 3}]
    ]

    assert Context.penalty(i, :c) == 1
  end

  # @tag :disabled
  test "Penalty of an intermediate context under causality :c (13)" do
    i = [
      [[[{:a, 0}, {:b, 0}, {:c, 0}], [{:a, 2}, {:b, 2}]], {:d, 6}, {:e, 3}],
      [[[{:a, 1}, {:b, 1}, {:c, 1}], [{:a, 2}, {:b, 2}]], {:d, 7}]
    ]

    assert Context.penalty(i, :c) == 0
  end

  # @tag :disabled
  test "Penalty of an intermediate context under causality :c (14)" do
    i = [
      [[[{:a, 0}, {:b, 0}, {:c, 0}], [{:a, 2}, {:b, 2}]], {:d, 6}, {:e, 3}],
      [{:f, 3}, {:g, 3}]
    ]

    assert Context.penalty(i, :c) == 0
  end

  # @tag :disabled
  test "Penalty of an intermediate context under causality :c (15)" do
    i = [
      [[[{:a, 0}, {:b, 0}, {:c, 0}], [{:a, 2}, {:b, 2}]], {:d, 6}, {:e, 3}],
      [[[{:f, 3}, {:g, 3}], [{:h, 8}]], {:i, 2}]
    ]

    assert Context.penalty(i, :c) == 0
  end

  ####################################################

  # @tag :disabled
  test "transformation of an intermediate :g-context" do
    i = [{:a, 2}, {:b, 3}]
    t = [{:e, 5}]
    g = {:g, 0}
    assert(Context.transform(i, t, g) == [{:a, 2}, {:b, 3}])
  end

  # @tag :disabled
  test "transformation of an intermediate :t-context" do
    i = 5
    t = 7
    g = {:t, 0}
    assert(Context.transform(i, t, g) == 5)
  end

  # @tag :disabled
  test "transformation of an intermediate :c-context (1)" do
    i = [[{:x, 3}, {:y, 2}]]
    t = [{:z, 2}]
    g = {:c, 0}
    assert(Context.transform(i, t, g) == [{:x, 3}, {:y, 2}, {:z, 2}])
  end

  # @tag :disabled
  test "transformation of an intermediate :c-context (2)" do
    i = [[[[{:a, 3}], [{:b, 2}]], {:c, 2}]]
    t = [{:z, 2}]
    g = {:c, 0}
    assert(Context.transform(i, t, g) == [[[{:a, 3}], [{:b, 2}]], {:c, 2}, {:z, 2}])
  end

  # @tag :disabled
  test "transformation of an intermediate :c-context (3)" do
    i = [[{:x, 0}, {:y, 0}], [{:x, 1}]]
    t = [{:z, 2}]
    g = {:c, 0}
    assert(Context.transform(i, t, g) == [[[{:x, 0}, {:y, 0}], [{:x, 1}]], {:z, 2}])
  end

  # @tag :disabled
  test "transformation of multiple intermediate contexts (1)" do
    is = []
    ts = []
    gs = []
    assert(Context.transform(is, ts, gs) == [])
  end

  # @tag :disabled
  test "transformation of multiple intermediate contexts (2)" do
    is = [[{:a, 2}, {:b, 3}], 5, [[{:x, 3}, {:y, 2}]]]
    ts = [[{:e, 5}], 7, [{:z, 2}]]
    gs = [{:g, 0}, {:t, 0}, {:c, 0}]
    cs = [[{:a, 2}, {:b, 3}], 5, [{:x, 3}, {:y, 2}, {:z, 2}]]
    assert(Context.transform(is, ts, gs) == cs)
  end
end
