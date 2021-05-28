OPENQASM 2.0;
include "qelib1.inc";
qreg q[9];
creg c[9];
h q[0];
h q[1];
h q[2];
h q[3];
h q[4];
h q[5];
h q[6];
h q[7];
x q[8];
x q[4];
x q[0];
x q[2];
x q[3];
x q[5];
h q[8];
cx q[0], q[8];
cx q[1], q[8];
cx q[2], q[8];
cx q[3], q[8];
cx q[4], q[8];
cx q[5], q[8];
cx q[6], q[8];
cx q[7], q[8];
x q[4];
x q[0];
x q[2];
x q[3];
x q[5];
h q[0];
h q[1];
h q[2];
h q[3];
h q[4];
h q[5];
h q[6];
h q[7];
measure q -> c;