 /*
  * Derek Hu
  * Creating s standard linux shell, implementing piping between three 
  * executable programs, reading and writing out to pipes
 */
 #include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/wait.h>

int main(){
	
	char* line=NULL;	
	size_t len = 0;
	ssize_t read;
	printf("Shell: ");
	getline(&line,&len,stdin);
	line[strlen(line)-1] = '\0';
			
	char* splitter = strtok(strdup(line)," | ");
	int numArgs = 0;
	
	//count the number of executables inputted
	while(splitter !=NULL){		
		
		numArgs++;
		splitter = strtok(NULL," | ");  
	}

	//execs[][0] will contain the name of the executable, execs[][1] contains NULL indicating there are no command line arguments
	char* execs[numArgs][2];		
	
	//separates the line based of | and build the matrix of executables
	int i = 0;
	splitter = strtok(line," | ");
	for(; i < numArgs; i++) {
		execs[i][0] = (char*)malloc(sizeof(char*));
		strcpy(execs[i][0],splitter);
	
		execs[i][1] = NULL;
		splitter = strtok(NULL," | ");  
	}

	
	// creating and launching pipes
	int firstConnection[2];
	pipe(firstConnection);
	
	int secondConnection[2];
	pipe(secondConnection);
	
	
	pid_t childpid = fork();
	
	//child process
	if(childpid == 0){
		
		//writing out to first connection pipe
		close(1);
		close(firstConnection[0]);
		dup(firstConnection[1]);
		execvp(execs[0][0], execs[0]);
	
	}
	
	//creating second process
	pid_t childpid2 = fork();
	if(childpid2 == 0){
		
		//reading in from first connection pipe
		close(0);
		close(firstConnection[1]);
		dup(firstConnection[0]);
		
		//writing out to second connection pipe
		close(1);
		close(secondConnection[0]);
		dup(secondConnection[1]);
		execvp(execs[1][0], execs[1]);
		
	}
	//closing both sides of first connection pipe 
	else{
		
		close(firstConnection[0]);
		close(firstConnection[1]);
		
	}
	
	//creating third process
	pid_t childpid3 = fork();
	if(childpid3 == 0){
		
		//reading in from second connection pipe
		close(secondConnection[1]);
		close(0);
		dup(secondConnection[0]);
		execvp(execs[2][0], execs[2]);
		
	}
	//close both sides of second connection pipe
	else{
		
		close(secondConnection[1]);
		close(secondConnection[0]);
	}
		
	//wait until all child processes are done
	while(wait(NULL) > 0){}
	
	return 0;
}
