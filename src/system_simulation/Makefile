compile: seesaw3.mo
	{ \
	set -e ;\
	mkdir -p seesaw3_build ;\
	cp seesaw3.mo  seesaw3_build/ ;\
	cd seesaw3_build  ;\
	omc -s seesaw3.mo  --tearingmethod=noTearing ;\
	mv seesaw3.makefile Makefile  ;\
	make -j 8  ;\
	}

simulate: seesaw3_build/seesaw3
	{ \
	set -e ;\
	cd seesaw3_build  ;\
	./seesaw3 -override outputFormat='csv',variableFilter='node_pos.*',stopTime='20' ;\
	mv seesaw3_res.csv .. ;\
	cd .. ;\
	}
