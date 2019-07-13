defmodule Test.BQuarp.MatchingTest do
  use ExUnit.Case
  alias Reactivity.Processing.Matching
  require Logger

  # @tag :disabled
  test "match with buffer with double queues for Event Streams and no guarantee (1)" do
    buffer = %{0 => [{7, []}, {5, []}], 1 => []}
    msg = {6, []}
    parent_id = 1
    tmap = %{0 => :event_stream, 1 => :event_stream}
    gmap = %{0 => [], 1 => []}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [{7, []}, {6, []}])
    assert(new_buffer == %{0 => [{5, []}], 1 => []})
  end

  # @tag :disabled
  test "match with buffer with double queues for Event Streams and no guarantee (2)" do
    buffer = %{0 => [{7, []}, {5, []}], 1 => []}
    msg = {6, []}
    parent_id = 1
    tmap = %{0 => :behaviour, 1 => :event_stream}
    gmap = %{0 => [], 1 => []}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [{5, []}, {6, []}])
    assert(new_buffer == %{0 => [{5, []}], 1 => []})
  end

  # @tag :disabled
  test "match with buffer with double queues for Event Streams and no guarantee (3)" do
    buffer = %{0 => [{7, []}, {5, []}], 1 => [{4, []}]}
    msg = {6, []}
    parent_id = 1
    tmap = %{0 => :behaviour, 1 => :behaviour}
    gmap = %{0 => [], 1 => []}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [{5, []}, {6, []}])
    assert(new_buffer == %{0 => [{5, []}], 1 => [{6, []}]})
  end

  # @tag :disabled
  test "match with buffer with empty single queue for an Event Stream and :t as a guarantee" do
    buffer = %{0 => []}
    msg = {55, [3]}
    parent_id = 0
    tmap = %{0 => :event_stream}
    gmap = %{0 => [{:t, 0}]}
    {:ok, match, context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [msg])
    assert(context == [3])
    assert(new_buffer == %{0 => []})
  end

  # @tag :disabled
  test "match with buffer with empty single queue for a Behaviour and :t as a guarantee" do
    buffer = %{0 => []}
    msg = {55, [3]}
    parent_id = 0
    tmap = %{0 => :behaviour}
    gmap = %{0 => [{:t, 0}]}
    {:ok, match, context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [msg])
    assert(context == [3])
    assert(new_buffer == %{0 => [msg]})
  end

  # @tag :disabled
  test "match with buffer with empty single queue for an Event Stream and :g as guarantee" do
    buffer = %{0 => []}
    msg = {1302, [[{:a, 2}, {:b, 3}]]}
    parent_id = 0
    tmap = %{0 => :event_stream}
    gmap = %{0 => [{:g, 0}]}
    {:ok, match, context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [msg])
    assert(context == [[{:a, 2}, {:b, 3}]])
    assert(new_buffer == %{0 => []})
  end

  # @tag :disabled
  test "match with buffer with empty single queue for a Behaviour and :g as guarantee" do
    buffer = %{0 => []}
    msg = {1302, [[{:a, 2}, {:b, 3}]]}
    parent_id = 0
    tmap = %{0 => :behaviour}
    gmap = %{0 => [{:g, 0}]}
    {:ok, match, context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [msg])
    assert(context == [[{:a, 2}, {:b, 3}]])
    assert(new_buffer == %{0 => [msg]})
  end

  # @tag :disabled
  test "match with buffer with non-empty single queue for an Event Stream and :t as guarantee" do
    buffer = %{0 => [{55, [3]}, {53, [4]}]}
    msg = {51, [5]}
    parent_id = 0
    tmap = %{0 => :event_stream}
    gmap = %{0 => [{:t, 0}]}
    {:ok, match, context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [msg])
    assert(context == [5])
    assert(new_buffer == %{0 => []})
  end

  # @tag :disabled
  test "match with buffer with non-empty single queue for a Behaviour and :t as guarantee" do
    buffer = %{0 => [{55, [3]}, {53, [4]}]}
    msg = {51, [5]}
    parent_id = 0
    tmap = %{0 => :behaviour}
    gmap = %{0 => [{:t, 0}]}
    {:ok, match, context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [msg])
    assert(context == [5])
    assert(new_buffer == %{0 => [msg]})
  end

  # @tag :disabled
  test "match with buffer with non-empty single queue for an Event Stream and :g as a guarantee" do
    buffer = %{0 => [{2, [[{:a, 3}]]}, {7, [[{:a, 4}]]}]}
    msg = {4, [[{:a, 5}]]}
    parent_id = 0
    tmap = %{0 => :event_stream}
    gmap = %{0 => [{:g, 0}]}
    {:ok, match, context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [msg])
    assert(context == [[{:a, 5}]])
    assert(new_buffer == %{0 => []})
  end

  # @tag :disabled
  test "match with buffer with non-empty single queue for a Behaviour and :g as a guarantee" do
    buffer = %{0 => [{2, [[{:a, 3}]]}, {7, [[{:a, 4}]]}]}
    msg = {4, [[{:a, 5}]]}
    parent_id = 0
    tmap = %{0 => :behaviour}
    gmap = %{0 => [{:g, 0}]}
    {:ok, match, context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [msg])
    assert(context == [[{:a, 5}]])
    assert(new_buffer == %{0 => [msg]})
  end

  # @tag :disabled
  test "match with buffer with double queues for Event Streams and :t as a guarantee (1)" do
    buffer = %{0 => [{7, [1]}, {5, [2]}], 1 => []}
    msg = {6, [1]}
    parent_id = 1
    tmap = %{0 => :event_stream, 1 => :event_stream}
    gmap = %{0 => [{:t, 0}], 1 => [{:t, 0}]}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [{7, [1]}, {6, [1]}])
    assert(new_buffer == %{0 => [{5, [2]}], 1 => []})
  end

  # @tag :disabled
  test "match with buffer with double queues for Event Streams and :t as a guarantee (2)" do
    buffer = %{0 => [{7, [1]}, {5, [2]}], 1 => []}
    msg = {6, [2]}
    parent_id = 1
    tmap = %{0 => :event_stream, 1 => :event_stream}
    gmap = %{0 => [{:t, 0}], 1 => [{:t, 0}]}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [{5, [2]}, {6, [2]}])
    assert(new_buffer == %{0 => [], 1 => []})
  end

  # @tag :disabled
  test "match with buffer with double queues for Event Streams and :t as a guarantee (3)" do
    buffer = %{0 => [{7, [1]}, {5, [2]}], 1 => []}
    msg = {6, [3]}
    parent_id = 0
    tmap = %{0 => :event_stream, 1 => :event_stream}
    gmap = %{0 => [{:t, 0}], 1 => [{:t, 0}]}
    assert(Matching.match(buffer, msg, parent_id, tmap, gmap) == :nomatch)
  end

  # @tag :disabled
  test "match with buffer with double queues for Event Streams and :t as a guarantee (4)" do
    buffer = %{0 => [{7, [1]}, {5, [2]}], 1 => [{4, [1]}]}
    msg = {6, [2]}
    parent_id = 1
    tmap = %{0 => :event_stream, 1 => :event_stream}
    gmap = %{0 => [{:t, 0}], 1 => [{:t, 0}]}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [{5, [2]}, {6, [2]}])
    assert(new_buffer == %{0 => [], 1 => []})
  end

    # @tag :disabled
  test "match with buffer with double queues for Behaviours and :t as a guarantee (1)" do
    buffer = %{0 => [{7, [1]}, {5, [2]}], 1 => []}
    msg = {6, [1]}
    parent_id = 1
    tmap = %{0 => :behaviour, 1 => :behaviour}
    gmap = %{0 => [{:t, 0}], 1 => [{:t, 0}]}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [{7, [1]}, {6, [1]}])
    assert(new_buffer == %{0 => [{7, [1]}, {5, [2]}], 1 => [{6, [1]}]})
  end

  # @tag :disabled
  test "match with buffer with double queues for Behaviours and :t as a guarantee (2)" do
    buffer = %{0 => [{7, [1]}, {5, [2]}], 1 => []}
    msg = {6, [2]}
    parent_id = 1
    tmap = %{0 => :behaviour, 1 => :behaviour}
    gmap = %{0 => [{:t, 0}], 1 => [{:t, 0}]}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [{5, [2]}, {6, [2]}])
    assert(new_buffer == %{0 => [{5, [2]}], 1 => [{6, [2]}]})
  end

  # @tag :disabled
  test "match with buffer with double queues for Behaviours and :t as a guarantee (3)" do
    buffer = %{0 => [{7, [1]}, {5, [2]}], 1 => []}
    msg = {6, [3]}
    parent_id = 0
    tmap = %{0 => :behaviour, 1 => :behaviour}
    gmap = %{0 => [{:t, 0}], 1 => [{:t, 0}]}
    assert(Matching.match(buffer, msg, parent_id, tmap, gmap) == :nomatch)
  end

  # @tag :disabled
  test "match with buffer with double queues for Behaviours and :t as a guarantee (4)" do
    buffer = %{0 => [{7, [1]}, {5, [2]}], 1 => [{4, [1]}]}
    msg = {6, [2]}
    parent_id = 1
    tmap = %{0 => :behaviour, 1 => :behaviour}
    gmap = %{0 => [{:t, 0}], 1 => [{:t, 0}]}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [{5, [2]}, {6, [2]}])
    assert(new_buffer == %{0 => [{5, [2]}], 1 => [{6, [2]}]})
  end

  # @tag :disabled
  test "match buffer with two non-empty queues and one empty queue for Event Streams and :t as Guarantee." do
    buffer = %{0 => [{7, [1]}, {5, [2]}], 1 => [{4, [1]}], 2 => []}
    msg = {6, [2]}
    parent_id = 1
    tmap = %{0 => :event_stream, 1 => :event_stream, 2 => :event_stream}
    gmap = %{0 => [{:t, 0}], 1 => [{:t, 0}], 2 => [{:t, 0}]}
    assert(Matching.match(buffer, msg, parent_id, tmap, gmap) == :nomatch)
  end

  # @tag :disabled
  test "match buffer with double queue for Behaviours and :g as a Guarantee (1)" do
    buffer = %{0 => [{7, [[{:s1, 1}]]}, {5, [[{:s1, 2}]]}], 1 => []}
    msg = {6, [[{:s2, 5}]]}
    parent_id = 1
    tmap = %{0 => :behaviour, 1 => :behaviour}
    gmap = %{0 => [{:g, 0}], 1 => [{:g, 0}]}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [{5, [[{:s1, 2}]]}, {6, [[{:s2, 5}]]}])
    assert(new_buffer == %{0 => [{5, [[{:s1, 2}]]}], 1 => [{6, [[{:s2, 5}]]}]})
  end

  # @tag :disabled
  test "match buffer with double queue for Behaviours and :g as a guarantee (2)" do
    buffer = %{0 => [{7, [[{:s1, 1}]]}, {5, [[{:s1, 2}]]}], 1 => []}
    msg = {6, [[{:s1, 2}]]}
    parent_id = 1
    tmap = %{0 => :behaviour, 1 => :behaviour}
    gmap = %{0 => [{:g, 0}], 1 => [{:g, 0}]}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [{5, [[{:s1, 2}]]}, {6, [[{:s1, 2}]]}])
    assert(new_buffer == %{0 => [{5, [[{:s1, 2}]]}], 1 => [{6, [[{:s1, 2}]]}]})
  end

  # @tag :disabled
  test "match buffer double queue for Behaviours and :g as a guarantee (3)" do
    buffer = %{0 => [{7, [[{:s1, 1}]]}, {5, [[{:s1, 2}]]}, {8, [[{:s1, 3}]]}], 1 => []}
    msg = {6, [[{:s1, 2}]]}
    parent_id = 1
    tmap = %{0 => :behaviour, 1 => :behaviour}
    gmap = %{0 => [{:g, 0}], 1 => [{:g, 0}]}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [{5, [[{:s1, 2}]]}, {6, [[{:s1, 2}]]}])
    assert(new_buffer == %{0 => [{5, [[{:s1, 2}]]}, {8, [[{:s1, 3}]]}], 1 => [{6, [[{:s1, 2}]]}]})
  end

  # @tag :disabled
  test "match buffer with double queue for Behaviours and :g as a guarantee (4)" do
    buffer = %{0 => [{7, [[{:s1, 1}]]}, {5, [[{:s1, 2}]]}], 1 => [{8, [[{:s1, 1}]]}]}
    msg = {6, [[{:s1, 2}]]}
    parent_id = 1
    tmap = %{0 => :behaviour, 1 => :behaviour}
    gmap = %{0 => [{:g, 0}], 1 => [{:g, 0}]}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [{5, [[{:s1, 2}]]}, {6, [[{:s1, 2}]]}])
    assert(new_buffer == %{0 => [{5, [[{:s1, 2}]]}], 1 => [{6, [[{:s1, 2}]]}]})
  end

  # @tag :disabled
  test "match buffer with triple queue for Behaviours and :g as a guarantee (1)" do
    buffer = %{0 => [{5, [[{:s1, 2}]]}, {7, [[{:s1, 3}]]}], 1 => [{20, [[{:s2, 5}]]}], 2 => []}
    msg = {6, [[{:s3, 2}]]}
    parent_id = 2
    tmap = %{0 => :behaviour, 1 => :behaviour, 2 => :behaviour}
    gmap = %{0 => [{:g, 0}], 1 => [{:g, 0}], 2 => [{:g, 0}]}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [{7, [[{:s1, 3}]]}, {20, [[{:s2, 5}]]}, {6, [[{:s3, 2}]]}])
    assert(
      new_buffer == %{
        0 => [{7, [[{:s1, 3}]]}],
        1 => [{20, [[{:s2, 5}]]}],
        2 => [{6, [[{:s3, 2}]]}]
      }
    )
  end

  # @tag :disabled
  test "match buffer with triple queue for Behaviours and :g as a guarantee (2)" do
    buffer = %{0 => [{7, [[{:s1, 2}]]}, {5, [[{:s1, 3}]]}], 1 => [{15, [[{:s1, 2}]]}], 2 => []}
    msg = {6, [[{:s3, 2}]]}
    parent_id = 2
    tmap = %{0 => :behaviour, 1 => :behaviour, 2 => :behaviour}
    gmap = %{0 => [{:g, 0}], 1 => [{:g, 0}], 2 => [{:g, 0}]}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [{7, [[{:s1, 2}]]}, {15, [[{:s1, 2}]]}, {6, [[{:s3, 2}]]}])
    assert(
      new_buffer == %{
        0 => [{7, [[{:s1, 2}]]}, {5, [[{:s1, 3}]]}],
        1 => [{15, [[{:s1, 2}]]}],
        2 => [{6, [[{:s3, 2}]]}]
      }
    )
  end

  # @tag :disabled
  test "match buffer with triple queue for Behaviours and :g as a guarantee (3)" do
    buffer = %{0 => [{7, [[{:s1, 2}]]}, {5, [[{:s1, 3}]]}], 1 => [{15, [[{:s1, 2}]]}], 2 => []}
    msg = {6, [{:s1, 3}]}
    parent_id = 2
    tmap = %{0 => :behaviour, 1 => :behaviour, 2 => :behaviour}
    gmap = %{0 => [{:g, 0}], 1 => [{:g, 0}], 2 => [{:g, 0}]}
    assert(Matching.match(buffer, msg, parent_id, tmap, gmap) == :nomatch)
  end

  # @tag :disabled
  test "match buffer with triple queue for Behaviours and :g, :t as Guarantees (1)" do
    buffer = %{0 => [{7, [[{:s1, 2}]]}, {5, [[{:s1, 3}]]}], 1 => [{15, [1]}, {11, [2]}], 2 => []}
    msg = {6, [2]}
    parent_id = 2
    tmap = %{0 => :behaviour, 1 => :behaviour, 2 => :behaviour}
    gmap = %{0 => [{:g, 0}], 1 => [{:t, 0}], 2 => [{:t, 0}]}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [{5, [[{:s1, 3}]]}, {11, [2]}, {6, [2]}])
    assert(new_buffer == %{0 => [{5, [[{:s1, 3}]]}], 1 => [{11, [2]}], 2 => [{6, [2]}]})
  end

  # @tag :disabled
  test "match buffer with triple queue for Behaviours and Event Streams and :g, :t as Guarantees (1)" do
    buffer = %{0 => [{7, [[{:s1, 2}]]}, {5, [[{:s1, 3}]]}], 1 => [{15, [1]}, {11, [2]}], 2 => []}
    msg = {6, [2]}
    parent_id = 2
    tmap = %{0 => :behaviour, 1 => :event_stream, 2 => :event_stream}
    gmap = %{0 => [{:g, 0}], 1 => [{:t, 0}], 2 => [{:t, 0}]}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [{5, [[{:s1, 3}]]}, {11, [2]}, {6, [2]}])
    assert(new_buffer == %{0 => [{5, [[{:s1, 3}]]}], 1 => [], 2 => []})
  end

  # @tag :disabled
  test "match buffer with double queue and :g + :t as a guarantee (1)" do
    buffer = %{0 => [{7, [[{:s1, 3}], 1]}, {5, [[{:s1, 3}], 2]}], 1 => [{11, [2]}], 2 => []}
    msg = {6, [[{:s1, 3}]]}
    parent_id = 2
    tmap = %{0 => :event_stream, 1 => :event_stream, 2 => :behaviour}
    gmap = %{0 => [{:g, 0}, {:t, 0}], 1 => [{:t, 0}], 2 => [{:g, 0}]}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [{5, [[{:s1, 3}], 2]}, {11, [2]}, {6, [[{:s1, 3}]]}])
    assert(new_buffer == %{0 => [], 1 => [], 2 => [{6, [[{:s1, 3}]]}]})
  end

  # @tag :disabled
  test "match buffer with double queue and :g + :t as a guarantee (2)" do
    buffer = %{0 => [{7, [[{:s1, 3}], 1]}, {5, [[{:s1, 3}], 2]}], 1 => [{11, [1]}], 2 => []}
    msg = {6, [1, [{:s1, 3}]]}
    parent_id = 2
    tmap = %{0 => :event_stream, 1 => :event_stream, 2 => :event_stream}
    gmap = %{0 => [{:g, 0}, {:t, 0}], 1 => [{:t, 0}], 2 => [{:t, 0}, {:g, 0}]}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [{7, [[{:s1, 3}], 1]}, {11, [1]}, {6, [1, [{:s1, 3}]]}])
    assert(new_buffer == %{0 => [{5, [[{:s1, 3}], 2]}], 1 => [], 2 => []})
  end

  # @tag :disabled
  test "match buffer with double queue and :g + :t as a guarantee (3)" do
    buffer = %{0 => [{7, [[{:s1, 3}], 1]}, {5, [[{:s1, 3}], 2]}], 1 => [{11, [1]}], 2 => []}
    msg = {6, [1, [{:s2, 5}]]}
    parent_id = 2
    tmap = %{0 => :event_stream, 1 => :event_stream, 2 => :event_stream}
    gmap = %{0 => [{:g, 0}, {:t, 0}], 1 => [{:t, 0}], 2 => [{:t, 0}, {:g, 0}]}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [{7, [[{:s1, 3}], 1]}, {11, [1]}, {6, [1, [{:s2, 5}]]}])
    assert(new_buffer == %{0 => [{5, [[{:s1, 3}], 2]}], 1 => [], 2 => []})
  end

  # @tag :disabled
  test "match buffer with double queue and :g + :t as a guarantee (4)" do
    buffer = %{0 => [{7, [[{:s1, 3}], 1]}, {5, [[{:s1, 3}], 2]}], 1 => [{11, [1]}], 2 => []}
    msg = {6, [1, [{:s1, 2}]]}
    parent_id = 2
    tmap = %{0 => :event_stream, 1 => :event_stream, 2 => :behaviour}
    gmap = %{0 => [{:g, 0}, {:t, 0}], 1 => [{:t, 0}], 2 => [{:t, 0}, {:g, 0}]}
    assert(Matching.match(buffer, msg, parent_id, tmap, gmap) == :nomatch)
  end

  # @tag :disabled
  test "match buffer with double queue and :g + :c as a guarantee (1)" do
    buffer = %{
      0 => [{7, [[{:s1, 3}]]}, {5, [[{:s1, 4}]]}],
      1 => [{11, [[{:s1, 2}], [{:a, 0}, {:b, 0}]]}, {14, [[{:s1, 3}], [{:a, 0}, {:b, 0}]]}],
      2 => []
    }
    msg = {4, [[{:a, 1}]]}
    parent_id = 2
    tmap = %{0 => :behaviour, 1 => :behaviour, 2 => :behaviour}
    gmap = %{0 => [{:g, 0}], 1 => [{:g, 0}, {:c, 0}], 2 => [{:c, 0}]}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, msg, parent_id, tmap, gmap)
    assert(match == [{7, [[{:s1, 3}]]}, {14, [[{:s1, 3}], [{:a, 0}, {:b, 0}]]}, {4, [[{:a, 1}]]}])
    assert(
      new_buffer == %{
        0 => [{7, [[{:s1, 3}]]}, {5, [[{:s1, 4}]]}],
        1 => [{14, [[{:s1, 3}], [{:a, 0}, {:b, 0}]]}],
        2 => [{4, [[{:a, 1}]]}]
      }
    )
  end

  # @tag :disabled
  test "match buffer with double queue and :g + :c as a guarantee (2)" do
    buffer = %{
      0 => [{7, [[{:s1, 3}]]}, {5, [[{:s1, 4}]]}],
      1 => [{11, [[{:s1, 2}], [{:a, 0}, {:b, 0}]]}, {14, [[{:s1, 3}], [{:a, 1}, {:b, 1}]]}],
      2 => []
    }
    msg = {4, [[{:a, 0}]]}
    parent_id = 2
    tmap = %{0 => :behaviour, 1 => :behaviour, 2 => :behaviour}
    gmap = %{0 => [{:g, 0}], 1 => [{:g, 0}, {:c, 0}], 2 => [{:c, 0}]}
    assert(Matching.match(buffer, msg, parent_id, tmap, gmap) == :nomatch)
  end
end
