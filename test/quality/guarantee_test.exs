defmodule Test.BQuarp.GuaranteeTest do
	use ExUnit.Case
	alias Reactivity.Quality.Guarantee

	test "combine guarantees (1)" do
		gss = 	[
						[{:t, 0}, {:g, 1}],
						[{:g, 0}],
						[{:t, 1}, {:c, 1}]
					]
		assert(Guarantee.combine(gss) == [{:c, 1}, {:g, 0}, {:t, 0}])
	end

	test "combine guarantees (2)" do
		gss = 	[
						[{:t, 0}, {:g, 1}],
					]
		assert(Guarantee.combine(gss) == [{:g, 1}, {:t, 0}])
	end

	#####################################################

	test "semantics (1)" do
		gs = [{:t, 0}, {:g, 1}]
		assert(Guarantee.semantics(gs) == :propagate)
	end

	test "semantics (2)" do
		gs = [{:g, 1}]
		assert(Guarantee.semantics(gs) == :update)
	end

	test "semantics (3)" do
		gs = [{:t, 0}]
		assert(Guarantee.semantics(gs) == :propagate)
	end
	
end