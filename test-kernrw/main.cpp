#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <mach/mach.h>
#include <libgeneral/macros.h>
#include "KernelRW.hpp"


int main(int argc, char **argv, char **envp){
	printf("Hello World! TODO: Get kernel r/w\n");
	mach_port_t fakethread = 0;
	mach_port_t transmissionPort = 0;
	cleanup([&]{
		if (transmissionPort) {
			mach_port_destroy(mach_task_self(), transmissionPort); transmissionPort = MACH_PORT_NULL;
		}
		if (fakethread) {
			thread_terminate(fakethread);
			mach_port_destroy(mach_task_self(), fakethread); fakethread = MACH_PORT_NULL;
		}
	});
	kern_return_t kr = 0;
	KernelRW krw;

	retassure(!(kr = thread_create(mach_task_self(), &fakethread)), "Failed to create fake thread");

	//set known state
	retassure(!(kr = thread_set_exception_ports(fakethread, EXC_BREAKPOINT, MACH_PORT_NULL, EXCEPTION_DEFAULT, ARM_THREAD_STATE64)), "Failed to set exception port to MACH_PORT_NULL");

	//set magic state
	{
		arm_thread_state64_t state = {};
		mach_msg_type_number_t statecnt = ARM_THREAD_STATE64_COUNT;
		memset(&state, 0x41, sizeof(state));
		retassure(!(kr = thread_set_state(fakethread, ARM_THREAD_STATE64, (thread_state_t)&state, ARM_THREAD_STATE64_COUNT)), "Failed to set fake thread state");
	}

	//get transmission port
	{
		exception_mask_t masks[EXC_TYPES_COUNT] = {};
		mach_msg_type_number_t masksCnt = 0;
		mach_port_t eports[EXC_TYPES_COUNT] = {};
		exception_behavior_t behaviors[EXC_TYPES_COUNT] = {};
		thread_state_flavor_t flavors[EXC_TYPES_COUNT] = {};
		do {
			retassure(!(kr = thread_get_exception_ports(fakethread, EXC_BREAKPOINT, masks, &masksCnt, eports, behaviors, flavors)), "Failed to get thread exception port");
			transmissionPort = eports[0];
		}while(transmissionPort == MACH_PORT_NULL);
	}

	krw.handoffPrimitivePatching(transmissionPort);
	printf("handoff done!\n");

	uint64_t kbase = krw.getKernelBase();
	printf("kernelbase=0x%016llx\n",kbase);
	sleep(1);
	uint64_t kbaseval = krw.kread64(kbase);
	printf("kbaseval=0x%016llx\n",kbaseval);

	printf("done\n");
	return 0;
}
