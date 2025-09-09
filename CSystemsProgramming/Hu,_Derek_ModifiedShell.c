//Derek Hu
//Period 4
//This program allows processes to run in the foreground and the background

#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include<time.h>
#include<unistd.h>
#include<sys/wait.h>
#include<sys/types.h>
#include<signal.h>

void handler(int signum);

int main(int argc, char* argv[]){
	
	signal(SIGCHLD, (void (*)(int))handler);
	
	size_t len = 0;
	ssize_t read;
	char* line = NULL;
	
	//gets first shell line
	printf("Enter command line: ");
	read = getline(&line, &len, stdin);
	line[strlen(line) - 1] = '\0';
	
	//checks quitting
	while(strcmp(line, "q") != 0){
		
		int numElements = 0;
		char** arr = NULL;
		char* splitter = strtok(line, " ");
	
		//splits command line argument
		while(splitter != NULL){
		
			arr = realloc(arr, sizeof(char*)*(numElements + 1));
			arr[numElements] = malloc(sizeof(char));
			strcpy(arr[numElements], splitter);
			numElements++;
			splitter = strtok(NULL, " ");
		}
		
		//adds null;
		arr = realloc(arr, sizeof(char*)*(numElements + 1));
		arr[numElements] = malloc(sizeof(char));
		arr[numElements] = NULL;
		numElements++;
		
		//Foreground
		if(strcmp(arr[numElements-2], "&") != 0) {
			pid_t childPid = fork();
		
			if(childPid == 0){
				setpgid(childPid, childPid);
				
				//process not found
				if (execvp(arr[0], arr) == -1) {
					printf("Process not found");
				}
				return -1;
			}
			else {	
				setpgid(childPid, childPid);
			
				if(strcmp(arr[numElements-2], "&") != 0) {
					//Give terminal to child and ignore signal
					tcsetpgrp(0, getpgid(childPid));
					signal(SIGTTOU, SIG_IGN);
					
					//Wait until child process terminates
					int status;
					waitpid(childPid, &status ,0);
					
					//Give terminal back to parent and restore signal
					tcsetpgrp(0, getpgid(0));
					signal(SIGTTOU, SIG_DFL);
				}
			}
		}
		
		
		//prompts for another shell line
		printf("\nEnter command line: ");
		read = getline(&line, &len, stdin);
		line[strlen(line) - 1] = '\0';
	}
		
	return 0;
}

void handler(int signum) {
	printf("we reached the handler");
	
	sigset_t newMask, oldMask;
	sigemptyset(&newMask);
	sigemptyset(&oldMask);
	
	sigaddset(&newMask, SIGCHLD);
	
	//Blocks signal
	sigprocmask(SIG_BLOCK, &newMask, &oldMask);

	//Waits on child 
	int status;
	waitpid(-1, &status, WNOHANG);
	
	//Unblocks signal
	sigprocmask(SIG_SETMASK, &oldMask, NULL);
}
