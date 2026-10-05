import sys          #this lets you read the terminal
import random       #to generate random values
import os           #to talk with the os to create folders
import subprocess   #to run other programs like xrun and iverilog commands
from datetime import datetime     #for timestamping logs

VALID_TESTS = ["test1", "test2", "test3", "test4"]

if len(sys.argv) < 2:
  print("cmd is: python3 run.py <test_name> [seed]")
  print(f"Test arguments are: {VALID_TESTS}")
  sys.exit(1)

test_name = sys.argv[1]

if len(sys.argv) < 3:
  seed = random.randint(1,999999)
else:
  seed = sys.argv[2]

if test_name not in VALID_TESTS:
  print(f"{test_name} is not a valid test")
  print(f"valid tests are {VALID_TESTS}")
  sys.exit(1)


os.makedirs("logs", exist_ok = True)
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
log_file  = f"logs/{test_name}_seed{seed}_{timestamp}.log"

print("=" * 50)
print(f"test_name: {test_name}")
print(f"seed: {seed}")
print(f"log_file_path: {log_file}")
print("=" * 50)


source_files   = "apb_inf.sv apb_master.sv apb_slave.sv tb_top.sv"
compiled_bin   = "sim"
compile_cmd    = f"iverilog -g2012 -o {compiled_bin} {source_files}"
sim_cmd        = f"vvp {compiled_bin} +TEST={test_name} +SEED={seed}"
print("=============Compiling the apb_interface=============")
compile_result = subprocess.run(compile_cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
compile_output = compile_result.stdout.decode()
print(f"OUTPUT\n{compile_output}")

if(compile_result.returncode != 0):
  print("[ERROR] Compilation falied")
  sys.exit(1)

print("[STEP 1] Compile Successful\n")

print("[STEP 2] Running Simulation...")
print(f"CMD: {sim_cmd}\n")

#Simulation part
with open(log_file, "w") as log:
  log.write(f"TEST     :   {test_name}\n")
  log.write(f"SEED     :   {seed}\n")
  log.write(f"COMMAND  :   {sim_cmd}\n")
  log.write(f"TIME     :   {timestamp}\n")
  log.write("=" * 50 + "\n\n")

  sim_process = subprocess.Popen(
      sim_cmd,
      shell  =  True,
      stdout =  subprocess.PIPE,
      stderr =  subprocess.STDOUT
  )

  for line in sim_process.stdout:
    decoded_line = line.decode()
    print(decoded_line, end="")
    log.write(decoded_line)

  sim_process.wait()

#Done

print(f"\n{'=' * 50}")
print(f"[Done] Log saved -> {log_file}")
print(f"{'=' * 50}\n")
