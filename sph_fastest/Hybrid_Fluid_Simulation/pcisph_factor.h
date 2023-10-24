//stf add 
// compute pcisph density error factor

#ifndef _PCISPH_FACTOR_H
#define _PCISPH_FACTOR_H

#include <vector>
#include "sph_kernel.cuh"
#include "sph_hybrid_system.h"

namespace sph
{
	float computeDensityErrorFactorSMS(float mass, float rest_density, float time_step, ParticleBufferList buff_list, int *cell_start, int *cell_end, BlockTask *block_task, int num_block, uint nump);  //����һ��float�͵� pcisph�ܶ��������

	//void computeGradWValuesSimple();
	
	float computeFactorSimple(float mass, float rest_density, float time_step, uint index, sumGrad *particle_host);
}

#endif/*_PCISPH_FACTOR_H*/