gas:
	forge snapshot
	forge test --nmc 'Fuzz|Invariant' --gas-report | sed -n '/|/,$$p' | sed '/^Ran /d' > .gas-report

gas2:
	forge test --nmc 'Fuzz|Invariant' --gas-report | sed -n '/|/,$$p' | sed '/^Ran /d' > .gas-report2

gas3:
	forge test --nmc 'Fuzz|Invariant' --gas-report | sed -n '/|/,$$p' | sed '/^Ran /d' > .gas-report3

cov:
	forge coverage --report lcov

inv:
	forge test --mc Invariant

invv:
	forge test --mc Invariant -vv

invvv:
	forge test --mc Invariant -vvv
