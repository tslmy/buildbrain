obj-m += brain-bu26154.o

KERNEL_DIR ?= ../../linux-brain

.PHONY: all clean
all:
	$(MAKE) -C $(KERNEL_DIR) M=$(CURDIR) modules

clean:
	$(MAKE) -C $(KERNEL_DIR) M=$(CURDIR) clean
