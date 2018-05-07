#make
#make install
#make init
#make web
#make clean

CC = arm-linux-gnueabihf-gcc

config = $(PWD)/config
init = $(PWD)/init
web = $(PWD)/web
webroot = $(web)/webroot
webserver = $(web)/websvr-goahead-2.18/LINUX
opt = ~/cpe_FileSystem/opt
page="cpe"

initEXE = lterouter
export initEXE
webEXE = router-web
export webEXE

#readdr = root@90.1.2.1:/opt
readdr = root@192.168.1.1:/opt

all:
	$(MAKE) -C $(init)
	cd $(webserver) && $(MAKE)

config:
	scp -r $(config)/* $(readdr)/config

init:
	$(MAKE) -C $(init)
	scp -r $(init)/*.sh $(init)/$(initEXE) $(readdr)/init/
	#cd $(init) && $(MAKE)
	
web:
	cd $(webserver) && $(MAKE) 
	cp $(webserver)/$(webEXE) $(webroot)/bin/
	scp -r $(webroot)/* $(readdr)/web/

clean:
	cd $(webserver) && $(MAKE) clean 
	cd $(init) && $(MAKE) clean 

opt:
	rm $(opt)/* -rf
	-mkdir $(opt) $(opt)/config $(opt)/init $(opt)/web $(opt)/log $(opt)/upgrade
	cp $(config)/* $(opt)/config/
	cp $(init)/*.sh $(init)/$(initEXE) $(opt)/init/
	cp $(webserver)/$(webEXE) $(webroot)/bin/
	cp -r $(webroot)/* $(opt)/web/
	#system.tar 恢复出厂设置使用 解压时必须进入对应的目录
	cd $(opt)/upgrade/;tar -cf system.tar ../*  

package:
	#网页升级包，升级后删除
	cd $(opt);tar -cf ~/ubuntushare/package/cpe.tar ./*

install:
	scp -r $(opt)/* $(readdr)

.PHONY:all clean config init web install 
