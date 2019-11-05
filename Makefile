

.PHONY documentation:
documentation:
	./Scripts/Documentation.sh

.PHONY xcframework:
xcframework:
	./Scripts/BuildForDistribution.sh
