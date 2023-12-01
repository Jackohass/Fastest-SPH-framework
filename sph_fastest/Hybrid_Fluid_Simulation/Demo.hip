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
#include "sph_arrangement.cuh.hip"

#undef max
#undef min
#define NOMINMAX

std::vector<float3> positions;
std::random_device rd;
std::mt19937 g(rd());

float3 make_float3(float, float, float);
ushort3 make_ushort3(ushort, ushort, ushort);

inline float3 operator-(const float3& left, const float3& right)
{
	return make_float3( left[0] - right[0], left[1] - right[1], left[2] - right[2] );
}

std::size_t const N = 120;

float const r_omega = static_cast<float>(0.15);
float const r_omega2 = r_omega * r_omega;
float const radius = static_cast<float>(2.0) * (static_cast<float>(2.0) * r_omega / static_cast<float>(N - 1));

uint buff_capacity_ = N * N * N;
uint nump_ = 0U;
ParticleBufferObject host_buff_;
ParticleBufferObject device_buff_;
ParticleBufferObject device_buff_temp_;

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
	device_buff_.allocate(buff_capacity_, kBuffTypeDevice);
	host_buff_.allocate(buff_capacity_, kBuffTypeHostPinned);
	device_buff_temp_.allocateSubBuffer(&device_buff_);

	//Generate test data
	float min_x = std::numeric_limits<float>::max();
	float max_x = std::numeric_limits<float>::min();
	positions.reserve(N * N * N);
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

				float l2 = x[0] * x[0] + x[1] * x[1] + x[2] * x[2];
				if (l2 < r_omega2)
				{
					x[0] += static_cast<float>(0.35);
					x[1] += static_cast<float>(0.35);
					x[2] += static_cast<float>(0.35);
					positions.push_back(x);
					if (min_x > x[0])
					{
						min_x = x[0];
					}
					if (max_x < x[0])
					{
						max_x = x[0];
					}
				}
			}
		}
	}
	std::shuffle(positions.begin(), positions.end(), g);
	printf("Number of particles: %d \n", static_cast<int>(positions.size()));

	//Add point set from the test data
	for (unsigned int i = 0; i < positions.size(); ++i)
	{
		addParticle(positions[i]);
	}

	BuffInit(device_buff_.get_buff_list(), nump_);
	std::cout << "Number of particles: " << nump_ << std::endl;

	host_buff_.transfer(device_buff_, 0, nump_, hipMemcpyHostToDevice);
	float cell_size = 0.03f / 80;
	ushort3 grid_size = make_ushort3(
		(ushort)ceil(1.0f / cell_size),
		(ushort)ceil(1.0f / cell_size),
		(ushort)ceil(1.0f / cell_size)
	);
	
	arrangement_ = new Arrangement(device_buff_, device_buff_temp_, nump_, buff_capacity_, cell_size, grid_size);

	int* d_index = arrangement_->getDevCellIndex();
	int* offset_data = arrangement_->getDevOffsetData();
	int* cell_offset = arrangement_->getDevCellOffset();
	int* cell_offsetM = arrangement_->getDevCellOffsetM();
	int* cell_nump = arrangement_->getDevCellNumP();
	int middle = nump_;

	middle = arrangement_->arrangeHybridMode9M();

	ParticleIdxRange tra_range(0, middle);      // [0, middle)

	computeDensityHybrid128n(cell_offsetM, tra_range, device_buff_.get_buff_list(), d_index, cell_offset, cell_nump, arrangement_->getBlockTasks(), arrangement_->getNumBlockSMSMode());

	//Neighborhood search result test
	auto& pointSet = nsearch.point_set(0);
	auto points = pointSet.GetPoints();

	std::cout << "Validate results" << std::endl;
	for (unsigned int i = 0; i < pointSet.n_points(); i++)
	{
		float3 point = ((float3*)points)[i];
		auto count = pointSet.n_neighbors(0, i);
		for (unsigned int j = 0; j < count; j++)
		{
			auto neighbor = pointSet.neighbor(0, i, j);
			auto diff = point - ((float3*)points)[neighbor];
			float squaredLength = diff[0] * diff[0] + diff[1] * diff[1] + diff[2] * diff[2];
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

	testCuNSearch();
	std::cout << "Finished Testing" << std::endl;
	getchar();
}