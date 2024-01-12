#include <hip/hip_runtime.h>

#include <iostream>
#include <vector>
#include <array>
#include <cmath>
#include <limits>
#include <random>

#include "sph_kernel.cuh.hip"
#include "sph_arrangement.cuh.hip"
#include "sph_particle.h.hip"

#undef max
#undef min
#define NOMINMAX

std::vector<float3> positions;
std::random_device rd;
std::mt19937 g(rd());

inline float3 operator-(const float3& left, const float3& right)
{
	return make_float3( left.x - right.x, left.y - right.y, left.z - right.z );
}

inline float4 operator-(const float4& left, const float4& right)
{
	return make_float4(left.x - right.x, left.y - right.y, left.z - right.z, left.w - right.w);
}

std::size_t const N = 120;

float const r_omega = static_cast<float>(0.15);
float const r_omega2 = r_omega * r_omega;
float const radius = static_cast<float>(2.0) * (static_cast<float>(2.0) * r_omega / static_cast<float>(N - 1));

uint buff_capacity_ = 881968;
uint nump_ = 0U;
sph::ParticleBufferObject host_buff_;
sph::ParticleBufferObject device_buff_;
sph::ParticleBufferObject device_buff_temp_;

void addParticle(float3 position)
{
	if (nump_ + 1 > buff_capacity_)
	{
		buff_capacity_ *= 2;
		host_buff_.reallocate(buff_capacity_);
		device_buff_.reallocate(buff_capacity_);
		device_buff_temp_.reallocate(buff_capacity_);
	}

	float4 pos_d;
	pos_d.x = position.x;
	pos_d.y = position.y;
	pos_d.z = position.z;
	pos_d.w = 0;

	host_buff_.get_buff_list().position_d[nump_] = pos_d;
	host_buff_.get_buff_list().final_position[nump_] = position * 0.9;

	++nump_;
}

void testFSPHF()
{
	device_buff_.allocate(buff_capacity_, sph::kBuffTypeDevice);
	host_buff_.allocate(buff_capacity_, sph::kBuffTypeHostPinned);
	device_buff_temp_.allocateSubBuffer(&device_buff_);

	//Generate test data
	float min_x = std::numeric_limits<float>::max();
	float max_x = std::numeric_limits<float>::min();
	positions.reserve(buff_capacity_);
	for (unsigned int i = 0; i < N; ++i)
	{
		for (unsigned int j = 0; j < N; ++j)
		{
			for (unsigned int k = 0; k < N; ++k)
			{
				float3 x = make_float3(
					r_omega * static_cast<float>(2.0 * static_cast<double>(i) / static_cast<double>(N - 1) - 1.0),
					r_omega * static_cast<float>(2.0 * static_cast<double>(j) / static_cast<double>(N - 1) - 1.0),
					r_omega * static_cast<float>(2.0 * static_cast<double>(k) / static_cast<double>(N - 1) - 1.0)
				);

				float l2 = x.x * x.x + x.y * x.y + x.z * x.z;
				if (l2 < r_omega2)
				{
					x.x += static_cast<float>(0.35);
					x.y += static_cast<float>(0.35);
					x.z += static_cast<float>(0.35);
					positions.push_back(x);
					if (min_x > x.x)
					{
						min_x = x.x;
					}			 
					if (max_x < x.x)
					{			 
						max_x = x.x;
					}
				}
			}
		}
	}
	std::shuffle(positions.begin(), positions.end(), g);
	printf("Number of particles: %d \n", static_cast<int>(positions.size()));

	// ## INITIALIZE SYSTEM
	sph::SystemParameter sysPara;

	sysPara.kernel = radius;//0.03f;
	sysPara.kernel_2 = sysPara.kernel * sysPara.kernel;

	sysPara.cell_size = sysPara.kernel;
	sysPara.grid_size = make_ushort3(
		(ushort)ceil(1.0f / sysPara.cell_size),
		(ushort)ceil(1.0f / sysPara.cell_size),
		(ushort)ceil(1.0f / sysPara.cell_size)
	);

	transSysParaToDevice(&sysPara);

	//Add point set from the test data
	for (unsigned int i = 0; i < positions.size(); ++i)
	{
		addParticle(positions[i]);
	}

	BuffInit(device_buff_.get_buff_list(), nump_);
	std::cout << "Number of particles: " << nump_ << std::endl;

	host_buff_.transfer(device_buff_, 0, nump_, hipMemcpyHostToDevice);
	printf("Host buffer transfer success\n");
	
	sph::Arrangement* arrangement_ = new sph::Arrangement(device_buff_, device_buff_temp_, nump_, buff_capacity_, sysPara.cell_size, sysPara.grid_size);
	printf("Arrangement success\n");
	printf("System initialization success\n");

	int* d_index = arrangement_->getDevCellIndex();
	int* offset_data = arrangement_->getDevOffsetData();
	int* cell_offset = arrangement_->getDevCellOffset();
	int* cell_offsetM = arrangement_->getDevCellOffsetM();
	int* cell_nump = arrangement_->getDevCellNumP();
	int middle = nump_;

	middle = arrangement_->arrangeHybridMode9M();
	printf("Arranged HybridMode success\n");

	sph::ParticleIdxRange tra_range(0, middle);      // [0, middle)
	printf("Gotten middle\n");

	Neighbours neigh(nump_);
	printf("Created Neighbours\n");

	sph::computeNeighbours(cell_offsetM, tra_range, device_buff_.get_buff_list(), d_index, cell_offset, cell_nump, arrangement_->getBlockTasks(), arrangement_->getNumBlockSMSMode(), neigh);
	printf("Computed neighbours\n");

	CUDA_SAFE_CALL(hipMemcpy(host_buff_.get_buff_list().position_d, device_buff_.get_buff_list().position_d, nump_ * sizeof(float4), hipMemcpyDeviceToHost));

	//Neighborhood search result test

	std::cout << "Validate results" << std::endl;
	for (unsigned int i = 0; i < nump_; i++)
	{
		float4 point = host_buff_.get_buff_list().position_d[i];
		for (unsigned int j = 0; j < neigh.counts[i]; j++)
		{
			int neighbor = neigh.neighbors[neigh.offsets[i] + j];
			float4 diff = point - host_buff_.get_buff_list().position_d[neighbor];
			float squaredLength = diff.x * diff.x + diff.y * diff.y + diff.z * diff.z;
			float distance = sqrt(squaredLength);

			if (distance > radius)
			{
				throw std::runtime_error("Not a neighbor");
			}
		}
	}
}

int main(int argc, char* argv[])
{
#ifdef DEBUG
	std::cout << "Debug Build:" << std::endl;

	if (sizeof(Real) == 4)
		std::cout << "Real = float" << std::endl;
	else if (sizeof(Real) == 8)
		std::cout << "Real = double" << std::endl;
#endif

	testFSPHF();
	std::cout << "Finished Testing" << std::endl;
	getchar();
}