OPENQASM 2.0;
include "qelib1.inc";

qreg q0[1];
qreg q1[1];
qreg q2[1];
qreg q3[1];
qreg q4[1];
qreg q5[1];
qreg q6[1];
qreg q7[1];
qreg q8[1];

x q2;
h q7;
h q7;
h q7;
cx q2, q7;
tdg q7;
cx q0, q7;
t q7;
cx q2, q7;
tdg q7;
cx q0, q7;
cx q0, q2;
tdg q2;
cx q0, q2;
t q0;
t q2;
t q7;
h q7;
h q7;
h q7;
x q2;
x q0;
h q6;
h q8;
h q6;
h q6;
cx q7, q6;
tdg q6;
cx q1, q6;
t q6;
cx q7, q6;
tdg q6;
cx q1, q6;
cx q1, q7;
tdg q7;
cx q1, q7;
t q1;
t q7;
t q6;
h q6;
h q6;
h q8;
h q8;
cx q2, q8;
tdg q8;
cx q0, q8;
t q8;
cx q2, q8;
tdg q8;
cx q0, q8;
cx q0, q2;
tdg q2;
cx q0, q2;
t q0;
t q2;
t q8;
h q8;
h q8;
h q8;
h q6;
cx q6, q5;
cx q6, q3;
cx q8, q7;
x q1;
x q7;
h q3;
h q6;
h q6;
h q6;
cx q8, q6;
tdg q6;
cx q1, q6;
t q6;
cx q8, q6;
tdg q6;
cx q1, q6;
cx q1, q8;
tdg q8;
cx q1, q8;
t q1;
t q8;
t q6;
h q6;
h q6;
h q3;
h q3;
cx q7, q3;
tdg q3;
cx q1, q3;
t q3;
cx q7, q3;
tdg q3;
cx q1, q3;
cx q1, q7;
tdg q7;
cx q1, q7;
t q1;
t q7;
t q3;
h q3;
h q3;
h q6;
h q3;
x q1;
cx q6, q4;
cx q5, q8;
h q5;
h q8;
h q5;
h q5;
cx q7, q5;
tdg q5;
cx q1, q5;
t q5;
cx q7, q5;
tdg q5;
cx q1, q5;
cx q1, q7;
tdg q7;
cx q1, q7;
t q1;
t q7;
t q5;
h q5;
h q5;
h q8;
h q8;
cx q2, q8;
tdg q8;
cx q0, q8;
t q8;
cx q2, q8;
tdg q8;
cx q0, q8;
cx q0, q2;
tdg q2;
cx q0, q2;
t q0;
t q2;
t q8;
h q8;
h q8;
h q8;
h q5;
x q0;
x q7;
cx q5, q8;