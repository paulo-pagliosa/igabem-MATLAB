# igabem-MATLAB

MATLAB code for isogeometric boundary element analysis of elastic solids modeled by watertight boundary representation forms.

The code is a complementary material of the paper [[1]](#ref1).

## Quick Start

1. Clone the repository:

   ```bash
   git clone https://github.com/paulo-pagliosa/igabem-MATLAB.git
   ```

2. Open MATLAB in the cloned directory and add it (with subfolders) to the MATLAB path:

   ```matlab
   addpath(genpath('.'))
   ```

3. Go to any subfolder of `tests/` — `beam`, `cylinder`, `plate` or `tee` — where the mesh data files and the corresponding script live, e.g.:

   ```matlab
   cd tests/tee
   ```

4. Run the script:

   ```matlab
   [mi, m] = testTee;
   ```

   This opens a `MeshInterface` window showing the deformed, color-mapped result. See the [examples](#examples) below for a step-by-step explanation of each script.

## MeshInterface User Manual

A brief user manual of `MeshInterface`, the graphic tool used to visualize meshes and analysis results, is available [here](docs/MeshInterface.md).

## Examples

The following worked examples, reproducing figures from [[1]](#ref1), are documented step by step:

- [Pressurized hollow cylinder](docs/examples/cylinder-example.md) (`tests/cylinder/testCylinder.m`)
- [Beam with multiple regions](docs/examples/beam-example.md) (`tests/beam/testBeam.m`)
- [Tee-shaped model under torque and uniform load](docs/examples/tee-example.md) (`tests/tee/testTee.m`)
- [Thick plate with holes](docs/examples/plate-example.md) (`tests/plate/testPlate.m`)

## References

<a id="ref1"></a>[1] M.A. Peres, G. Sanches, A. Paiva, P. Pagliosa, [Parallel isogeometric boundary element analysis
with T-splines on CUDA](https://www.sciencedirect.com/science/article/abs/pii/S0045782524005528), Computer Methods in Applied Mechanics and Engineering, Volume 432, Part A, 2024.

## Credits

Developed by M.A. Peres and [P. Pagliosa](https://www.facom.ufms.br/~pagliosa).

## Contact

If you have questions related to the use of the code, a bug to report or a
feature you would like to request, please send an e-mail to:<br/>
*<mapperes@gmail.com>*<br/>
*<ppagliosa@gmail.com>*
