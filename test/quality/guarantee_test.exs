defmodule Test.BQuarp.GuaranteeTest do
  use ExUnit.Case
  alias Reactivity.Quality.Guarantee

  test "combine guarantees (1)" do
    gss = [
      [{:t, 0}, {:g, 1}],
      [{:g, 0}],
      [{:t, 1}, {:c, 1}]
    ]

    assert(Guarantee.combine(gss) == [{:c, 1}, {:g, 0}, {:t, 0}])
  end

  test "combine guarantees (2)" do
    gss = [
      [{:t, 0}, {:g, 1}]
    ]

    assert(Guarantee.combine(gss) == [{:g, 1}, {:t, 0}])
  end

  test "combine guarantees (3)" do
    gss = [
      [{:t, 0}, {:g, 1}],
      []
    ]

    assert(Guarantee.combine(gss) == [{:g, 1}, {:t, 0}])
  end

  test "combine guarantees (4)" do
    gss = [
      [],
      [{:t, 0}, {:c, 1}]
    ]

    assert(Guarantee.combine(gss) == [{:c, 1}, {:t, 0}])
  end

  test "combine guarantees (5)" do
    gss = [
      [],
      []
    ]

    assert(Guarantee.combine(gss) == [])
  end
end
