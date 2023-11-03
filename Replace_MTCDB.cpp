#include<iostream>
#include<fstream>
#include<string>
#include<vector>

using namespace std;

int main()
{
    //string files[] = {
	vector<string> files({
        /*"cuda_call_check.h",
		"cuda_math.cuh",
		"cuda_prescan",
		"gl_main.cpp",
		"gl_main_header.h",
		"gl_texture.h",
		"gpu_model.cu",
		"gpu_model.cuh",
		"gpu_model.h",
		"gpu_model_reader.cpp",
		"gpu_model_reader.h",
		"high_resolution_timer.h",
		"nv_gui.h",
		"parameters.cpp",
		"parameters.h",
		"pcisph_factor.cpp",
		"pcisph_factor.h",
		"save_screen.h",
		"sph_arrangement.cu",
		"sph_arrangement.cuh",
		"sph_data.h",
		"sph_header.h",
		"sph_hybrid_system.cpp",
		"sph_hybrid_system.h",
		"sph_kernel.cu",
		"sph_kernel.cuh",
		"sph_kernel_shared_data.cuh",
		"sph_marching_cube.cpp",
		"sph_marching_cube.h",
		"sph_parameter.h",
		"sph_particle.cpp",
		"sph_particle.h",
		"sph_timer.cpp",
		"sph_timer.h",
		"sph_utils.cuh",
		"cuda_prescan/prefix_sum.cu",
		"cuda_prescan/scan.cu",
		"cuda_prescan/scan.cuh",
		"cuda_prescan/scan_kern.cuh"*/
		"gl_main.cpp",
		"gpu_model_reader.cpp",
		"parameters.cpp",
		"pcisph_factor.cpp",
		"sph_marching_cube.cpp",
		"sph_particle.cpp",
		"sph_timer.cpp",
		//"main.h",
		"nv_gui.h",
		"parameters.h",
		"cuda_prescan/scan.cuh",
		"cuda_prescan/scan_kern.cuh",
		"gl_main_header.h",
		"gl_texture.h",
		"gpu_model.cuh",
		"gpu_model.h",
		"gpu_model_reader.h",
		"high_resolution_timer.h",
		"pcisph_factor.h",
		//"save_screen.h",
		"sph_arrangement.cuh",
		"sph_hybrid_system.h",
		"sph_kernel.cuh",
		"sph_kernel_shared_data.cuh",
		"sph_marching_cube.h",
		"sph_parameter.h",
		"sph_particle.h",
		"sph_timer.h",
		"sph_utils.cuh",
		"cuda_prescan/prefix_sum.cu",
		"cuda_prescan/scan.cu",
		"gpu_model.cu",
		"sph_arrangement.cu",
		"sph_hybrid_system.cpp",
		"sph_kernel.cu"
    });

    string before = "{\n"
		"\"directory\": \"D:/projects/master_thesis/programs/HIPIFIED-FSPHF/sph_fastest/\",\n"
		"\"command\": \"\\\"C:/Program Files/AMD/ROCm/5.5/bin/clang++.exe\\\" -x c++ \\\"D:/projects/master_thesis/programs/HIPIFIED-FSPHF/sph_fastest/Hybrid_Fluid_Simulation/";
	string middle = "\\\" -std=c++14 -Wall -fms-compatibility-version=19.10 -Wmicrosoft -Wno-invalid-token-paste -Wno-unknown-pragmas -Wno-unused-value -fsyntax-only \\\"-D_MT\\\" \\\"-DWIN32\\\" \\\"-DWIN64\\\" \\\"-DNDEBUG\\\" \\\"-D_CONSOLE\\\" \\\"-D_DEBUG_FUNCTIONAL_MACHINERY\\\" -isystem\\\"E:/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Tools/MSVC/14.37.32822/include\\\" -isystem\\\"E:/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Tools/MSVC/14.37.32822/atlmfc/include\\\" -isystem\\\"E:/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Auxiliary/VS/include\\\" -isystem\\\"C:/Program Files (x86)/Windows Kits/10/Include/10.0.10240.0/ucrt\\\" -isystem\\\"C:/Program Files (x86)/Windows Kits/8.1/Include/um\\\" -isystem\\\"C:/Program Files (x86)/Windows Kits/8.1/Include/shared\\\" -isystem\\\"C:/Program Files (x86)/Windows Kits/8.1/Include/winrt\\\" -isystem\\\"Hybrid_Fluid_Simulation/GL_LIB/glew_64/include\\\" -isystem\\\"Hybrid_Fluid_Simulation/GL_LIB/freeglut_64/include\\\" -isystem\\\"Hybrid_Fluid_Simulation/json/include\\\" -I\\\"D:/projects/master_thesis/programs/Fastest-SPH-framework/sph_fastest/Hybrid_Fluid_Simulation/json/include\\\"\",\n"
		"\"file\": \"D:/projects/master_thesis/programs/HIPIFIED-FSPHF/sph_fastest/Hybrid_Fluid_Simulation/";
	string after = "\"\n}\n";
    ofstream output ("compile_commands.json");
    if (output.is_open())
    {
		output << "[\n";
		for (int i = 0; i < files.size()-1; i++)
		{
			output << before << files.begin()[i] << middle << files.begin()[i] << after << ",\n";
		}
		output << before << files.begin()[files.size()-1] << middle << files.begin()[files.size()-1] << after << "]\n";
        output.close();
    }

    return 0;
}