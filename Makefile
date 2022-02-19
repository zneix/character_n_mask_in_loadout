.PHONY: all

all: clean publish

clean:
	rm -rf *.zip character_n_mask_in_loadout

publish: clean
	mkdir character_n_mask_in_loadout && \
	cp *.lua character_n_mask_in_loadout && \
	zip character_n_mask_in_loadout.zip -r character_n_mask_in_loadout \

push: publish
	rsync -aP character_n_mask_in_loadout.zip dank:~/cdn/pdthmods/downloads/
