defmodule Test.BQuarp.ContextTest do
	use ExUnit.Case
	alias Reactivity.Quality.Guarantee
	alias Reactivity.Quality.Context

  #@tag: disabled
  test "Combine single context in case of :fu" do
    context = nil
    contexts = [context]
    combined_context = Context.combine(contexts, :fu)
    assert(combined_context == nil)
  end

  #@tag: disabled
  test "Combine contexts in case of :fu" do
    context1 = nil
    context2 = nil
    contexts = [context1, context2]
    combined_context = Context.combine(contexts, :fu)
    assert(combined_context == nil)
  end

  #@tag: disabled
  test "Combine single context in case of :fp" do
    context = nil
    contexts = context
    combined_context = Context.combine(contexts, :fp)
    assert(combined_context == nil)
  end

  #@tag: disabled
  test "Combine contexts in case of :fp" do
    context1 = nil
    context2 = nil
    contexts = [context1, context2]
    combined_context = Context.combine(contexts, :fp)
    assert(combined_context == nil)
  end

  #@tag: disabled
  test "Combine single context in case of :t (1)" do
    context = 5
    contexts = [context]
    combined_context = Context.combine(contexts, :t)
    assert(combined_context == 5)
  end

  #@tag: disabled
  test "Combine single context in case of :t (2)" do
    context = {2, 4}
    contexts = [context]
    combined_context = Context.combine(contexts, :t)
    assert(combined_context == {2, 4})
  end

	#@tag :disabled
  test "Combine contexts in case of :t (1)" do
    context1 = 5
    context2 = {2, 4}
    contexts = [context1, context2]
    combined_context = Context.combine(contexts, :t)
    assert(combined_context == {2,5})
  end

  #@tag :disabled
  test "Combine contexts in case of :t (2)" do
    context1 = 5
    context2 = 5
    contexts = [context1, context2]
    combined_context = Context.combine(contexts, :t)
    assert(combined_context == 5)
  end

  #@tag :disabled
  test "Combine contexts in case of :t (3)" do
    context1 = {1, 3}
    context2 = {2, 4}
    contexts = [context1, context2]
    combined_context = Context.combine(contexts, :t)
    assert(combined_context == {1, 4})
  end

  #@tag :disabled
  test "Combine contexts in case of :t (4)" do
    context1 = {1, 3}
    context2 = {2, 4}
    context3 = 5
    contexts = [context1, context2, context3]
    combined_context = Context.combine(contexts, :t)
    assert(combined_context == {1, 5})
  end

  #@tag :disabled
  test "Combine contexts in case of :t (5)" do
    context1 = 3
    context2 = 4
    context3 = 5
    contexts = [context1, context2, context3]
    combined_context = Context.combine(contexts, :t)
    assert(combined_context == {3, 5})
  end

  #@tag :disabled
  test "Combine single context in case of :g (1)" do
    context = [{:s1, 5}]
    contexts = [context]
    combined_context = Context.combine(contexts, :g)
    assert(combined_context == [{:s1, 5}])
  end

  #@tag :disabled
  test "Combine single context in case of :g (2)" do
    context = [{:s1, 5}, {:s2, 7}]
    contexts = [context]
    combined_context = Context.combine(contexts, :g)
    assert(combined_context == [{:s1, 5}, {:s2, 7}])
  end

  #@tag :disabled
  test "Combine contexts in case of :g (1)" do
    context1 = [{:s1, 5}]
    contexts = [context1]
    combined_context = Context.combine(contexts, :g)
    assert(combined_context == [{:s1, 5}])
  end

  #@tag :disabled
  test "Combine contexts in case of :g (2)" do
    context1 = [{:s1, 5}, {:s2, 7}]
    contexts = [context1]
    combined_context = Context.combine(contexts, :g)
    assert(combined_context == [{:s1, 5}, {:s2, 7}])
  end

  #@tag :disabled
  test "Combine contexts in case of :g (3)" do
    context1 = [{:s1, 5}]
    context2 = [{:s2, 7}]
    contexts = [context1, context2]
    combined_context = Context.combine(contexts, :g)
    assert(combined_context == [{:s1, 5}, {:s2, 7}])
  end

  #@tag :disabled
  test "Combine contexts in case of :g (4)" do
    context1 = [{:s1, 5}]
    context2 = [{:s1, 5}, {:s2, 7}]
    contexts = [context1, context2]
    combined_context = Context.combine(contexts, :g)
    assert(combined_context == [{:s1, 5}, {:s2, 7}])
  end

  #@tag :disabled
  test "Combine contexts in case of :g (5)" do
    context1 = [{:s1, 5}]
    context2 = [{:s1, 3}, {:s2, 7}]
    contexts = [context1, context2]
    combined_context = Context.combine(contexts, :g)
    assert(combined_context == [{:s1, {3, 5}}, {:s2, 7}])
  end

  #@tag :disabled
  test "Combine contexts in case of :g (6)" do
    context1 = [{:s1, {3, 5}}]
    context2 = [{:s1, 2}, {:s2, 7}]
    contexts = [context1, context2]
    combined_context = Context.combine(contexts, :g)
    assert(combined_context == [{:s1, {2, 5}}, {:s2, 7}])
  end

  #@tag :disabled
  test "Combine contexts in case of :g (7)" do
    context1 = [{:s1, {3, 5}}, {:s2, 4}]
    context2 = [{:s1, 2}, {:s2, 7}]
    contexts = [context1, context2]
    combined_context = Context.combine(contexts, :g)
    assert(combined_context == [{:s1, {2, 5}}, {:s2, {4, 7}}])
  end

  #@tag :disabled
  test "Combine contexts in case of :g (8)" do
    context1 = [{:s1, {3, 5}}, {:s2, 4}]
    context2 = [{:s2, 7}, {:s1, 2}]
    contexts = [context1, context2]
    combined_context = Context.combine(contexts, :g)
    assert(combined_context == [{:s1, {2, 5}}, {:s2, {4, 7}}])
  end

  #@tag :disabled
  test "Combine contexts in case of :g (9)" do
    context1 = [{:s1, {3, 5}}, {:s2, 4}]
    context2 = [{:s2, 7}, {:s1, 2}]
    context3 = [{:s3, 4}, {:s2, {3, 5}}]
    contexts = [context1, context2, context3]
    combined_context = Context.combine(contexts, :g)
    assert(combined_context == [{:s1, {2, 5}}, {:s2, {3, 7}}, {:s3, 4}])
  end

  #@tag :disabled
  test "Combine contexts in case of :g (10)" do
    context1 = [{{:bob@MSI, :temperature1}, {3, 5}}, {{:bob@MSI, :temperature2}, 4}]
    context2 = [{{:bob@MSI, :temperature2}, 7}, {{:bob@MSI, :temperature1}, 2}]
    contexts = [context1, context2]
    combined_context = Context.combine(contexts, :g)
    assert(combined_context == [{{:bob@MSI, :temperature1}, {2, 5}}, {{:bob@MSI, :temperature2}, {4, 7}}])
  end

  #@tag :disabled
  test "Combine single context in case of :c (1)" do
    context = [{:a, 0}, {:b, 0}]
    contexts = [context]
    combined_context = Context.combine(contexts, :c)
    assert(combined_context == [[{:a, 0}, {:b, 0}]])
  end

  #@tag :disabled
  test "Combine single context in case of :c (2)" do
    context = [[[{:a, 0}], [{:b, 0}]], {:c, 0}]
    contexts = [context]
    combined_context = Context.combine(contexts, :c)
    assert(combined_context == [[[[{:a, 0}], [{:b, 0}]], {:c, 0}]])
  end

	#@tag :disabled
  test "Combine contexts in case of :c (1)" do
  	context1 = [{:a, 0}, {:b, 0}]
  	context2 = [{:a, 1}]
  	contexts = [context1, context2]
  	combined_context = Context.combine(contexts, :c)
  	assert(combined_context == [[{:a, 0}, {:b, 0}], [{:a, 1}]])
  end

  #@tag :disabled
  test "Combine contexts in case of :c (2)" do
    context1 = [[[{:a, 0}], [{:b, 0}]], {:c, 0}]
    context2 = [{:a, 1}]
    contexts = [context1, context2]
    combined_context = Context.combine(contexts, :c)
    assert(combined_context == [[[[{:a, 0}], [{:b, 0}]], {:c, 0}], [{:a, 1}]])
  end

  ##############################################################

  #@tag :disabled
  test "Penalty of a context in update fifo :fu (1)" do
  	context = nil
  	assert Context.penalty(context, :fu) == 0
  end

  #@tag :disabled
  test "Penalty of a context in update fifo :fp (1)" do
    context = nil
    assert Context.penalty(context, :fp) == 0
  end

  #@tag :disabled
  test "Penalty of a context in glitch freedom :g (2)" do
    context = [{:s1, {1, 3}}, {:s2, 5}]
    assert Context.penalty(context, :g) == 2
  end

  #@tag :disabled
  test "Penalty of a context in glitch freedom :g (3)" do
    context = [{:s1, {1, 3}}, {:s2, {2, 5}}]
    assert Context.penalty(context, :g) == 3
  end

  #@tag :disabled
  test "Penalty of a context in glitch freedom :g (4)" do
    context = [{:s1, {1, 3}}, {:s2, {2, 5}}, {:s3, 5}]
    assert Context.penalty(context, :g) == 3
  end


  #@tag :disabled
  test "Penalty of a context in time-synch :t (1)" do
    context = 5
    assert Context.penalty(context, :t) == 0
  end

  #@tag :disabled
  test "Penalty of a context in time-synch :t (2)" do
    context = {1, 5}
    assert Context.penalty(context, :t) == 4
  end


  #@tag :disabled
  test "Penalty of a context under causality :c (1)" do
  	context = [[{:a, 1}], [{:b, 4}]]
  	assert Context.penalty(context, :c) == 0
  end

  #@tag :disabled
  test "Penalty of a context under causality :c (2)" do
  	context = [[{:a, 1}], [{:a, 4}]]
  	assert Context.penalty(context, :c) == 0
  end

  #@tag :disabled
  test "Penalty of a context under causality :c (3)" do
  	context = [[{:a, 3}], [{:a, 1}, {:b, 2}]]
  	assert Context.penalty(context, :c) == 0
  end

  #@tag :disabled
  test "Penalty of a context under causality :c (4)" do
  	context = [[{:a, 1}], [{:a, 4}, {:b, 2}]]
  	assert Context.penalty(context, :c) == 3
  end

  #@tag :disabled
  test "Penalty of a context under causality :c (5)" do
  	context = [[{:a, 0}, {:b, 0}, {:c, 0}], [{:a, 2}, {:b, 2}]]
  	assert Context.penalty(context, :c) == 0
  end

  #@tag :disabled
  test "Penalty of a context under causality :c (6)" do
  	context = [[{:a, 3}, {:b, 3}, {:c, 3}], [{:a, 2}, {:b, 2}]]
  	assert Context.penalty(context, :c) == 1
  end

  #@tag :disabled
  test "Penalty of a context under causality :c (7)" do
  	context = [[{:a, 3}, {:b, 3}], [{:c, 5}, {:d, 8}]]
  	assert Context.penalty(context, :c) == 0
  end

  #@tag :disabled
  test "Penalty of a context under causality :c (8)" do
  	context = [[[[{:a, 0}, {:b, 0}, {:c, 0}], [{:a, 2}, {:b, 2}]], {:d, 6}], [{:a, 1}]]
  	assert Context.penalty(context, :c) == 1
  end

  #@tag :disabled
  test "Penalty of a context under causality :c (9)" do
  	context = [[[[{:a, 0}, {:b, 0}, {:c, 0}], [{:a, 2}, {:b, 2}]], {:d, 6}], [{:a, 0}]]
  	assert Context.penalty(context, :c) == 2
  end

  #@tag :disabled
  test "Penalty of a context under causality :c (10)" do
  	context = [[[[{:a, 0}, {:b, 0}, {:c, 0}], [{:a, 2}, {:b, 2}]], {:d, 6}], [{:a, 5}]]
  	assert Context.penalty(context, :c) == 0
  end

  #@tag :disabled
  test "Penalty of a context under causality :c (11)" do
  	context = [
  							[[[{:a, 0}, {:b, 0}, {:c, 0}], [{:a, 2}, {:b, 2}]], {:d, 6}], 
  							[[[{:a, 1}, {:b, 1}, {:c, 1}], [{:a, 2}, {:b, 2}]], {:d, 7}]
  						]
  	assert Context.penalty(context, :c) == 0
  end

  #@tag :disabled
  test "Penalty of a context under causality :c (12)" do
  	context = [
  							[[[{:a, 0}, {:b, 0}, {:c, 0}], [{:a, 2}, {:b, 2}]], {:d, 6}], 
  							[[[{:a, 1}, {:b, 1}, {:c, 1}], [{:a, 2}, {:b, 2}]], {:d, 7}, {:e, 3}]
  						]
  	assert Context.penalty(context, :c) == 1
  end

  #@tag :disabled
  test "Penalty of a context under causality :c (13)" do
  	context = [
  							[[[{:a, 0}, {:b, 0}, {:c, 0}], [{:a, 2}, {:b, 2}]], {:d, 6}, {:e, 3}], 
  							[[[{:a, 1}, {:b, 1}, {:c, 1}], [{:a, 2}, {:b, 2}]], {:d, 7}]
  						]
  	assert Context.penalty(context, :c) == 0
  end

  #@tag :disabled
  test "Penalty of a context under causality :c (14)" do
  	context = [
  							[[[{:a, 0}, {:b, 0}, {:c, 0}], [{:a, 2}, {:b, 2}]], {:d, 6}, {:e, 3}], 
  							[{:f, 3}, {:g, 3}]
  						]
  	assert Context.penalty(context, :c) == 0
  end

  #@tag :disabled
  test "Penalty of a context under causality :c (15)" do
  	context = [
  							[[[{:a, 0}, {:b, 0}, {:c, 0}], [{:a, 2}, {:b, 2}]], {:d, 6}, {:e, 3}], 
  							[[[{:f, 3}, {:g, 3}], [{:h, 8}]], {:i, 2}]
  						]
  	assert Context.penalty(context, :c) == 0
  end

  ######################################################

  #@tag :disabled
	test "combine context lists (1)" do
		guaranteess = [
			[{:t, 1}, {:g, 0}],
			[{:t, 0}, {:g, 1}]
		]
		contextss = [
			[{4, 5}, [{:a, 3}, {:b, 2}]],
			[3, [{:a, 3}, {:c, 8}]]
		]
	assert(Context.combine(contextss, guaranteess) == 
		[[{:a, 3}, {:b, 2}, {:c, 8}], {3, 5}])
	end

	#@tag :disabled
	test "combine context lists (2)" do
		guaranteess = [
			[{:t, 1}, {:g, 0}]
		]
		contextss = [	
			[{4, 5}, [{:a, 3}, {:b, 2}]]
		]
	assert(Context.combine(contextss, guaranteess) == 
		[[{:a, 3}, {:b, 2}], {4, 5}])
	end

  #@tag :disabled
  test "combine context lists (3)" do
    guaranteess = [
      [{:fp, 0}, {:t, 1}, {:g, 0}],
      [{:t, 1}, {:g, 0}]
    ]
    contextss = [
      [nil, {4, 5}, [{:a, 3}, {:b, 2}]],
      [5, [{:b, 2}]]
    ]
  assert(Context.combine(contextss, guaranteess) == 
    [nil, [{:a, 3}, {:b, 2}], {4, 5}])
  end

  #@tag :disabled
  test "combine context lists (4)" do
    guaranteess = [ 
      [{:fu, 0}, {:t, 1}, {:g, 0}],
      [{:c, 0}, {:g, 1}],
      [{:fu, 0}, {:c, 0}]
    ]
    contextss = [ 
      [nil, {4, 5}, [{:a, 3}, {:b, 2}]],
      [[{:c, 1}, {:d, 1}], [{:a, 2}, {:e, 9}]],
      [nil, [{:c, 2}, {:d, 2}, {:f, 2}]]
    ]
    assert(Context.combine(contextss, guaranteess) ==
      [ [[{:c, 1}, {:d, 1}], [{:c, 2}, {:d, 2}, {:f, 2}]],
        nil,
        [{:a, {2, 3}}, {:b, 2}, {:e, 9}],
        {4, 5}
      ])
  end

	#@tag :disabled
	test "combine context lists (5)" do
		guaranteess = [
			[{:t, 1}, {:g, 0}],
			[{:c, 0}, {:g, 1}],
			[{:c, 0}]
		]
		contextss = [	
			[{4, 5}, [{:a, 3}, {:b, 2}]],
			[[{:c, 1}, {:d, 1}], [{:a, 2}, {:e, 9}]],
			[[{:c, 2}, {:d, 2}, {:f, 2}]]
		]
	assert(Context.combine(contextss, guaranteess) ==
		[	[[{:c, 1}, {:d, 1}], [{:c, 2}, {:d, 2}, {:f, 2}]],
			[{:a, {2, 3}}, {:b, 2}, {:e, 9}],
			{4, 5}
		])
	end

	####################################################

	#@tag :disabled
	test "sufficient quality (1)" do
		guaranteess = [
			[{:t, 1}, {:g, 0}],
			[{:t, 0}, {:g, 1}]
		]
		contextss = [
			[{4, 5}, [{:a, 3}, {:b, 2}]],
			[3, [{:a, 3}, {:c, 8}]]
		]
		combinedgs = Guarantee.combine(guaranteess)
		combinedcs = Context.combine(contextss, guaranteess)	
		assert(Context.sufficient_quality?(combinedcs, combinedgs) == false)
	end

	#@tag :disabled
	test "sufficient quality (2)" do
		guaranteess = [
			[{:t, 1}, {:g, 0}],
			[{:t, 0}, {:g, 1}]
		]
		contextss = [	
			[3, [{:a, 3}, {:b, 2}]],
			[3, [{:a, 3}, {:c, 8}]]
		]
		combinedgs = Guarantee.combine(guaranteess)
		combinedcs = Context.combine(contextss, guaranteess)	
		assert(Context.sufficient_quality?(combinedcs, combinedgs) == true)
	end

	#@tag :disabled
	test "sufficient quality (3)" do
		guaranteess = [
			[{:t, 1}, {:g, 0}],
			[{:t, 0}, {:g, 1}]
		]
		contextss = [
			[3, [{:a, 3}, {:b, 2}]],
			[3, [{:a, {4, 5}}, {:c, 8}]]
		]
		combinedgs = Guarantee.combine(guaranteess)
		combinedcs = Context.combine(contextss, guaranteess)
		assert(Context.sufficient_quality?(combinedcs, combinedgs) == false)
	end

	#@tag :disabled
	test "sufficient quality (4)" do
		guaranteess = [
			[{:t, 1}, {:g, 1}],
			[{:t, 0}, {:g, 1}]
		]
		contextss = [	
			[3, [{:a, 4}, {:b, 2}]],
			[3, [{:a, {4, 5}}, {:c, 8}]]
		]
		combinedgs = Guarantee.combine(guaranteess)
		combinedcs = Context.combine(contextss, guaranteess)	
		assert(Context.sufficient_quality?(combinedcs, combinedgs) == true)
	end

	#@tag :disabled
	test "sufficient quality (5)" do
		guaranteess = [
			[{:t, 1}, {:g, 1}],
			[{:c, 0}, {:g, 1}],
			[{:c, 0}]
		]
		contextss = [	
			[{4, 5}, [{:a, 3}, {:b, 2}]],
			[[{:c, 1}, {:d, 1}], [{:a, 2}, {:e, 9}]],
			[[{:c, 2}, {:d, 2}, {:f, 2}]]
		]
		combinedgs = Guarantee.combine(guaranteess)
		combinedcs = Context.combine(contextss, guaranteess)
		assert(Context.sufficient_quality?(combinedcs, combinedgs) == false)
	end

	#@tag :disabled
	test "sufficient quality (6)" do
		guaranteess = [
			[{:t, 1}, {:g, 1}],
			[{:c, 0}, {:g, 1}],
			[{:c, 0}]
		]
		contextss = [	
			[{4, 5}, [{:a, 3}, {:b, 2}]],
			[[{:c, 3}, {:d, 3}], [{:a, 2}, {:e, 9}]],
			[[{:c, 2}, {:d, 2}, {:f, 2}]]
		]
		combinedgs = Guarantee.combine(guaranteess)
		combinedcs = Context.combine(contextss, guaranteess)	
		assert(Context.sufficient_quality?(combinedcs, combinedgs) == true)
	end

	#@tag :disabled
	test "sufficient quality (7)" do
		guaranteess = [
			[{:t, 1}, {:g, 0}],
			[{:c, 0}, {:g, 1}],
			[{:c, 0}]
		]
		contextss = [	
			[{4, 5}, [{:a, 3}, {:b, 2}]],
			[[{:c, 3}, {:d, 3}], [{:a, 2}, {:e, 9}]],
			[[{:c, 2}, {:d, 2}, {:f, 2}]]
		]
		combinedgs = Guarantee.combine(guaranteess)
		combinedcs = Context.combine(contextss, guaranteess)
		assert(Context.sufficient_quality?(combinedcs, combinedgs) == false)
	end

  #@tag :disabled
  test "sufficient quality (8)" do
    guaranteess = [
      [{:fu, 0}, {:g, 1}],
      [{:t, 0}, {:g, 1}]
    ]
    contextss = [ 
      [nil, [{:a, 4}, {:b, 2}]],
      [3, [{:a, {4, 5}}, {:c, 8}]]
    ]
    combinedgs = Guarantee.combine(guaranteess)
    combinedcs = Context.combine(contextss, guaranteess)
    assert(Context.sufficient_quality?(combinedcs, combinedgs) == true)
  end

	####################################################

  #@tag :disabled
  test "transformation of intermediate :fu-context" do
    context = nil
    trans = nil
    guarantee = {:fu, 0}
    assert(Context.transform(context, trans, guarantee) == nil)
  end

  #@tag :disabled
  test "transformation of intermediate :fp-context" do
    context = nil
    trans = nil
    guarantee = {:fp, 0}
    assert(Context.transform(context, trans, guarantee) == nil)
  end

	#@tag :disabled
	test "transformation of intermediate :g-context" do
		context = [{:a, 2}, {:b, 3}]
		trans = [{:e, 5}]
		guarantee = {:g, 0}
		assert(Context.transform(context, trans, guarantee) == [{:a, 2}, {:b, 3}])
	end

	#@tag :disabled
	test "transformation of intermediate :t-context" do
		context = 5
		trans = 7
		guarantee = {:t, 0}
		assert(Context.transform(context, trans, guarantee) == 5)
	end

	#@tag :disabled
	test "transformation of intermediate :c-context (1)" do
		context = [[{:x, 3}, {:y, 2}]]
		trans = [{:z, 2}]
		guarantee = {:c, 0}
		assert(Context.transform(context, trans, guarantee) == [{:x, 3}, {:y, 2}, {:z, 2}])
	end

  #@tag :disabled
  test "transformation of intermediate :c-context (2)" do
    context = [[[[{:a, 3}], [{:b, 2}]], {:c, 2}]]
    trans = [{:z, 2}]
    guarantee = {:c, 0}
    assert(Context.transform(context, trans, guarantee) == [[[{:a, 3}], [{:b, 2}]], {:c, 2}, {:z, 2}])
  end

	#@tag :disabled
	test "transformation of intermediate :c-context (3)" do
		context = [[{:x, 0}, {:y, 0}], [{:x, 1}]]
		trans = [{:z, 2}]
		guarantee = {:c, 0}
		assert(Context.transform(context, trans, guarantee) == [[[{:x, 0}, {:y, 0}], [{:x, 1}]], {:z, 2}])
	end

	#@tag :disabled
	test "transformation of multiple intermediate contexts" do
		contexts = [[{:a, 2}, {:b, 3}], 5, [[{:x, 3}, {:y, 2}]]]
		transs = [[{:e, 5}], 7, [{:z, 2}]]
		guarantees = [{:g, 0}, {:t, 0}, {:c, 0}]
		res = [[{:a, 2}, {:b, 3}], 5, [{:x, 3}, {:y, 2}, {:z, 2}]]
		assert(Context.transform(contexts, transs, guarantees) == res)
	end

end