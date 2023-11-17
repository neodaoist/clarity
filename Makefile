gas:
	forge snapshot
	forge test --nmc 'Fuzz|Invariant' --gas-report | sed -n '/|/,$$p' | sed '/^Ran /d' > .gas-report
