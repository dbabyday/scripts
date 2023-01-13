SELECT sys_context('USERENV', 'NETWORK_PROTOCOL') as network_protocol FROM dual;

/*

	tcp  - not encrypted
	tcps - encrypted

*/