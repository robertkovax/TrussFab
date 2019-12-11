seesaw3_res.csv:
	{ \
	set -e ;\
	mkdir seesaw3_build -p ;\
	cp seesaw3.mo  seesaw3_build/ ;\
	cd seesaw3_build  ;\
	omc -s seesaw3.mo  --tearingmethod=noTearing ;\
	mv seesaw3.makefile Makefile  ;\
	make -j 8  ;\
	./seesaw3 -override outputFormat='csv',variableFilter='node_pos.*',stopTime='20' ;\
	mv seesaw3_res.csv .. ;\
	cd .. ;\
	rm -rf seesaw3_build ;\
	}
