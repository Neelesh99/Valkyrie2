OPENQASM 2.0;
include "qelib1.inc";
qreg q[10];
creg c[10];
h q[0];
h q[1];
h q[2];
h q[3];
h q[4];
h q[5];
h q[6];
h q[7];
h q[8];
x q[9];
x q[4];
x q[0];
x q[2];
x q[3];
x q[5];
x q[6];
h q[9];
cx q[0], q[9];
cx q[1], q[9];
cx q[2], q[9];
cx q[3], q[9];
cx q[4], q[9];
cx q[5], q[9];
cx q[6], q[9];
cx q[7], q[9];
cx q[8], q[9];
x q[4];
x q[0];
x q[2];
x q[3];
x q[5];
x q[6];
h q[0];
h q[1];
h q[2];
h q[3];
h q[4];
h q[5];
h q[6];
h q[7];
h q[8];
measure q -> c;