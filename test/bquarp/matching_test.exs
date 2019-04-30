defmodule Test.BQuarp.MatchingTest do
  use ExUnit.Case
  alias BQuarp.Matching
  require Logger

  #@tag :disabled
  test "match with buffer with empty single queue and :t as a guarantee" do
  	buffer = %{0 => []}
  	message = {55, [3]}
  	parent_id = 0
  	guarantees = %{0 => [{:t, 0}]}
  	{:ok, match, context, new_buffer} = Matching.match(buffer, message, parent_id, guarantees)
  	assert(match == [message])
  	assert(context == [3])
  	assert(new_buffer == %{0 => []})
  end

  #@tag :disabled
  test "match with buffer with empty single queue and :g as a guarantee" do
  	buffer = %{0 => []}
  	message = {1302, [[{:a, 2}, {:b, 3}]]}
  	parent_id = 0
  	guarantees = %{0 => [{:g, 0}]}
  	{:ok, match, context, new_buffer} = Matching.match(buffer, message, parent_id, guarantees)
  	assert(match == [message])
  	assert(context == [[{:a, 2}, {:b, 3}]])
  	assert(new_buffer == %{0 => [message]})
  end

  #@tag :disabled
  test "match with buffer with non-empty single queue and :t as a guarantee" do
  	buffer = %{0 => [{55, [3]}, {53, [4]}]}
  	message = {51, [5]}
  	parent_id = 0
  	guarantees = %{0 => [{:t, 0}]}
  	{:ok, match, context, new_buffer} = Matching.match(buffer, message, parent_id, guarantees)
  	assert(match == [message])
  	assert(context == [5])
  	assert(new_buffer == %{0 => []})
  end

  #@tag :disabled
  test "match with buffer with non-empty single queue and :g as a guarantee" do
  	buffer = %{0 => [{2, [[{:a, 3}]]}, {7, [[{:a, 4}]]}]}
  	message = {4, [[{:a, 5}]]}
  	parent_id = 0
  	guarantees = %{0 => [{:g, 0}]}
  	{:ok, match, context, new_buffer} = Matching.match(buffer, message, parent_id, guarantees)
  	assert(match == [message])
  	assert(context == [[{:a, 5}]])
  	assert(new_buffer == %{0 => [message]})
  end

  #@tag :disabled
  test "match with buffer with non-empty double queue and :t as a guarantee (1)" do
  	buffer = %{0 => [{7, [1]}, {5, [2]}], 1 => []}
  	message = {6, [1]}
  	parent_id = 1
  	guarantees = %{0 => [{:t, 0}], 1 => [{:t, 0}]}
  	{:ok, match, _context, new_buffer} = Matching.match(buffer, message, parent_id, guarantees)
  	assert(match == [{7, [1]}, {6, [1]}])
  	assert(new_buffer == %{0 => [{5, [2]}], 1 => []})
  end

  #@tag :disabled
  test "match with buffer with non-empty double queue and :t as a guarantee (2)" do
  	buffer = %{0 => [{7, [1]}, {5, [2]}], 1 => []}
  	message = {6, [2]}
  	parent_id = 1
  	guarantees = %{0 => [{:t, 0}], 1 => [{:t, 0}]}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, message, parent_id, guarantees)
    assert(match == [{5, [2]}, {6, [2]}])
    assert(new_buffer == %{0 => [], 1 => []})
  end

  #@tag :disabled
  test "match with buffer with non-empty double queue and :t as a guarantee (3)" do
    buffer = %{0 => [{7, [1]}, {5, [2]}], 1 => []}
    message = {6, [3]}
    parent_id = 0
    guarantees = %{0 => [{:t, 0}], 1 => [{:t, 0}]}
    assert(Matching.match(buffer, message, parent_id, guarantees) == :nomatch)
  end

  #@tag :disabled
  test "match with buffer with non-empty double queue and :t as a guarantee (4)" do
  	buffer = %{0 => [{7, [1]}, {5, [2]}], 1 => [{4, [1]}]}
  	message = {6, [2]}
  	parent_id = 1
  	guarantees = %{0 => [{:t, 0}], 1 => [{:t, 0}]}
  	{:ok, match, _context, new_buffer} = Matching.match(buffer, message, parent_id, guarantees)
  	assert(match == [{5, [2]}, {6, [2]}])
  	assert(new_buffer == %{0 => [], 1 => []})
  end

  #@tag :disabled
  test "match buffer with two non-empty queues and one empty queue" do
  	buffer = %{0 => [{7, [1]}, {5, [2]}], 1 => [{4, [1]}], 2 => []}
  	message = {6, [2]}
  	parent_id = 1
  	guarantees = %{0 => [{:t, 0}], 1 => [{:t, 0}], 2 => [{:t, 0}]}
  	assert(Matching.match(buffer, message, parent_id, guarantees) == :nomatch)
  end

  #@tag :disabled
  test "match buffer with double queue and :g as a guarantee (1)" do
  	buffer = %{0 => [{7, [[{:s1, 1}]]}, {5, [[{:s1, 2}]]}], 1 => []}
  	message = {6, [[{:s2, 5}]]}
  	parent_id = 1
  	guarantees = %{0 => [{:g, 0}], 1 => [{:g, 0}]}
  	{:ok, match, _context, new_buffer} = Matching.match(buffer, message, parent_id, guarantees)
  	assert(match == [{5, [[{:s1, 2}]]}, {6, [[{:s2, 5}]]}])
  	assert(new_buffer == %{0 => [{5, [[{:s1, 2}]]}], 1 => [{6, [[{:s2, 5}]]}]})
  end

  #@tag :disabled
  test "match buffer with double queue and :g as a guarantee (2)" do
  	buffer = %{0 => [{7, [[{:s1, 1}]]}, {5, [[{:s1, 2}]]}], 1 => []}
    message = {6, [[{:s1, 2}]]}
    parent_id = 1
    guarantees = %{0 => [{:g, 0}], 1 => [{:g, 0}]}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, message, parent_id, guarantees)
    assert(match == [{5, [[{:s1, 2}]]}, {6, [[{:s1, 2}]]}])
    assert(new_buffer == %{0 => [{5, [[{:s1, 2}]]}], 1 => [{6, [[{:s1, 2}]]}]})
  end

  #@tag :disabled
  test "match buffer double queue and :g as a guarantee (3)" do
  	buffer = %{0 => [{7, [[{:s1, 1}]]}, {5, [[{:s1, 2}]]}, {8, [[{:s1, 3}]]}], 1 => []}
  	message = {6, [[{:s1, 2}]]}
  	parent_id = 1
  	guarantees = %{0 => [{:g, 0}], 1 => [{:g, 0}]}
  	{:ok, match, _context, new_buffer} = Matching.match(buffer, message, parent_id, guarantees)
  	assert(match == [{5, [[{:s1, 2}]]}, {6, [[{:s1, 2}]]}])
  	assert(new_buffer == %{0 => [{5, [[{:s1, 2}]]}, {8, [[{:s1, 3}]]}], 1 => [{6, [[{:s1, 2}]]}]})
  end

  #@tag :disabled
  test "match buffer with double queue and :g as a guarantee (4)" do
  	buffer = %{0 => [{7, [[{:s1, 1}]]}, {5, [[{:s1, 2}]]}], 1 => [{8, [[{:s1, 1}]]}]}
  	message = {6, [[{:s1, 2}]]}
  	parent_id = 1
  	guarantees = %{0 => [{:g, 0}], 1 => [{:g, 0}]}
  	{:ok, match, _context, new_buffer} = Matching.match(buffer, message, parent_id, guarantees)
  	assert(match == [{5, [[{:s1, 2}]]}, {6, [[{:s1, 2}]]}])
  	assert(new_buffer == %{0 => [{5, [[{:s1, 2}]]}], 1 => [{6, [[{:s1, 2}]]}]})
  end

  #@tag :disabled
  test "match buffer with triple queue and :g as a guarantee (1)" do
  	buffer = %{
      0 => [{5, [[{:s1, 2}]]}, {7, [[{:s1, 3}]]}], 
      1 => [{20, [[{:s2, 5}]]}], 
      2 => []}
  	message = {6, [[{:s3, 2}]]}
  	parent_id = 2
  	guarantees = %{0 => [{:g, 0}], 1 => [{:g, 0}], 2 => [{:g, 0}]}
  	{:ok, match, _context, new_buffer} = Matching.match(buffer, message, parent_id, guarantees)
  	assert(match == [{7, [[{:s1, 3}]]}, {20, [[{:s2, 5}]]}, {6, [[{:s3, 2}]]}])
  	assert(new_buffer == %{
      0 => [{7, [[{:s1, 3}]]}], 
      1 => [{20, [[{:s2, 5}]]}], 
      2 => [{6, [[{:s3, 2}]]}]})
  end

  #@tag :disabled
	test "match buffer with triple queue and :g as a guarantee (2)" do
  	buffer = %{
      0 => [{7, [[{:s1, 2}]]}, {5, [[{:s1, 3}]]}], 
      1 => [{15, [[{:s1, 2}]]}], 
      2 => []}
  	message = {6, [[{:s3, 2}]]}
  	parent_id = 2
  	guarantees = %{0 => [{:g, 0}], 1 => [{:g, 0}], 2 => [{:g, 0}]}
  	{:ok, match, _context, new_buffer} = Matching.match(buffer, message, parent_id, guarantees)
  	assert(match == [{7, [[{:s1, 2}]]}, {15, [[{:s1, 2}]]}, {6, [[{:s3, 2}]]}])
  	assert(new_buffer == %{
      0 => [{7, [[{:s1, 2}]]}, {5, [[{:s1, 3}]]}], 
      1 => [{15, [[{:s1, 2}]]}], 
      2 => [{6, [[{:s3, 2}]]}]})
  end

  #@tag :disabled
	test "match buffer with triple queue and :g as a guarantee (3)" do
  	buffer = %{
      0 => [{7, [[{:s1, 2}]]}, {5, [[{:s1, 3}]]}], 
      1 => [{15, [[{:s1, 2}]]}], 
      2 => []}
  	message = {6, [{:s1, 3}]}
  	parent_id = 2
  	guarantees = %{0 => [{:g, 0}], 1 => [{:g, 0}], 2 => [{:g, 0}]}
  	assert(Matching.match(buffer, message, parent_id, guarantees) == :nomatch)
  end

  #@tag :disabled
  test "match buffer with triple queue and :g, :t as a guarantee (1)" do
    buffer = %{
      0 => [{7, [[{:s1, 2}]]}, {5, [[{:s1, 3}]]}], 
      1 => [{15, [1]}, {11, [2]}], 
      2 => []}
    message = {6, [2]}
    parent_id = 2
    guarantees = %{0 => [{:g, 0}], 1 => [{:t, 0}], 2 => [{:t, 0}]}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, message, parent_id, guarantees)
    assert(match == [{5, [[{:s1, 3}]]}, {11, [2]}, {6, [2]}])
    assert(new_buffer == %{
      0 => [{5, [[{:s1, 3}]]}], 
      1 => [], 
      2 => []})
  end

  #@tag :disabled
  test "match buffer with double queue and :g + :t as a guarantee (1)" do
    buffer = %{
      0 => [{7, [[{:s1, 3}], 1]}, {5, [[{:s1, 3}], 2]}], 
      1 => [{11, [2]}], 
      2 => []}
    message = {6, [[{:s1, 3}]]}
    parent_id = 2
    guarantees = %{0 => [{:g, 0}, {:t, 0}], 1 => [{:t, 0}], 2 => [{:g, 0}]}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, message, parent_id, guarantees)
    assert(match == [{5, [[{:s1, 3}], 2]}, {11, [2]}, {6, [[{:s1, 3}]]}])
    assert(new_buffer == %{
      0 => [], 
      1 => [], 
      2 => [{6, [[{:s1, 3}]]}]})
  end

  #@tag :disabled
  test "match buffer with double queue and :g + :t as a guarantee (2)" do
    buffer = %{
      0 => [{7, [[{:s1, 3}], 1]}, {5, [[{:s1, 3}], 2]}], 
      1 => [{11, [1]}], 
      2 => []}
    message = {6, [1, [{:s1, 3}]]}
    parent_id = 2
    guarantees = %{0 => [{:g, 0}, {:t, 0}], 1 => [{:t, 0}], 2 => [{:t, 0}, {:g, 0}]}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, message, parent_id, guarantees)
    assert(match == [{7, [[{:s1, 3}], 1]}, {11, [1]}, {6, [1, [{:s1, 3}]]}])
    assert(new_buffer == %{
      0 => [{5, [[{:s1, 3}], 2]}], 
      1 => [], 
      2 => []})
  end

  #@tag :disabled
  test "match buffer with double queue and :g + :t as a guarantee (3)" do
    buffer = %{
      0 => [{7, [[{:s1, 3}], 1]}, {5, [[{:s1, 3}], 2]}], 
      1 => [{11, [1]}], 
      2 => []}
    message = {6, [1, [{:s2, 5}]]}
    parent_id = 2
    guarantees = %{0 => [{:g, 0}, {:t, 0}], 1 => [{:t, 0}], 2 => [{:t, 0}, {:g, 0}]}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, message, parent_id, guarantees)
    assert(match == [{7, [[{:s1, 3}], 1]}, {11, [1]}, {6, [1, [{:s2, 5}]]}])
    assert(new_buffer == %{
      0 => [{5, [[{:s1, 3}], 2]}], 
      1 => [], 
      2 => []})
  end

  #@tag :disabled
  test "match buffer with double queue and :g + :t as a guarantee (4)" do
    buffer = %{
      0 => [{7, [[{:s1, 3}], 1]}, {5, [[{:s1, 3}], 2]}], 
      1 => [{11, [1]}], 
      2 => []}
    message = {6, [1, [{:s1, 2}]]}
    parent_id = 2
    guarantees = %{0 => [{:g, 0}, {:t, 0}], 1 => [{:t, 0}], 2 => [{:t, 0}, {:g, 0}]}
    assert(Matching.match(buffer, message, parent_id, guarantees) == :nomatch)
  end

  #@tag :disabled
  test "match buffer with double queue and :g + :c as a guarantee (1)" do
    buffer = %{
      0 => [{7, [[{:s1, 3}]]}, {5, [[{:s1, 4}]]}], 
      1 => [{11, [[{:s1, 2}], [{:a, 0}, {:b, 0}]]}, {14, [[{:s1, 3}], [{:a, 0}, {:b, 0}]]}], 
      2 => []}
    message = {4, [[{:a, 1}]]}
    parent_id = 2
    guarantees = %{0 => [{:g, 0}], 1 => [{:g, 0}, {:c, 0}], 2 => [{:c, 0}]}
    {:ok, match, _context, new_buffer} = Matching.match(buffer, message, parent_id, guarantees)
    assert(match == [{7, [[{:s1, 3}]]}, {14, [[{:s1, 3}], [{:a, 0}, {:b, 0}]]}, {4, [[{:a, 1}]]}])
    assert(new_buffer == %{
      0 => [{7, [[{:s1, 3}]]}, {5, [[{:s1, 4}]]}], 
      1 => [{14, [[{:s1, 3}], [{:a, 0}, {:b, 0}]]}], 
      2 => [{4, [[{:a, 1}]]}]})
  end

  #@tag :disabled
  test "match buffer with double queue and :g + :c as a guarantee (2)" do
    buffer = %{
      0 => [{7, [[{:s1, 3}]]}, {5, [[{:s1, 4}]]}], 
      1 => [{11, [[{:s1, 2}], [{:a, 0}, {:b, 0}]]}, {14, [[{:s1, 3}], [{:a, 1}, {:b, 1}]]}], 
      2 => []}
    message = {4, [[{:a, 0}]]}
    parent_id = 2
    guarantees = %{0 => [{:g, 0}], 1 => [{:g, 0}, {:c, 0}], 2 => [{:c, 0}]}
    assert(Matching.match(buffer, message, parent_id, guarantees) == :nomatch)
  end
end