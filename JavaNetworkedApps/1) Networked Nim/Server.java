//Derek Hu, Ian Huang
//Towering Nim Server. Processes turns, winning and losing for the two players. 

import java.net.*;
import java.util.*;

import javax.swing.JOptionPane;

import java.io.*;

public class Server {

	//Setup
	private Scanner[] readers;
	private PrintWriter[] writers;
	private int playerTurn;				//[0,1]
	private final int PORT_NUM = 4242;
	private String[] players;

	public Server(){

		readers = new Scanner[2];
		writers = new PrintWriter[2];
		players = new String[2];
		
		
	
		try{
			//Set up the server socket, print IP and port info 
			ServerSocket server = new ServerSocket(PORT_NUM);
			
			//Accept two players and set up the readers and writers
			Socket sock1 = server.accept();
			Socket sock2 = server.accept();
			
			readers[0] = new Scanner(sock1.getInputStream());
			readers[1] = new Scanner(sock2.getInputStream());
			

			//Randomly determine who goes first
			playerTurn = (int)(Math.random() * 2);
			
			//Get the names of the two players
			for(int i = 0; i < 2; i++) {
				players[i] = readers[i].nextLine();
			}
			
			//Send the names to opposing player and indicate who goes first
			writers[0] = new PrintWriter(sock1.getOutputStream());
			writers[1] = new PrintWriter(sock2.getOutputStream());
			
			
			String result="";
			
			//Determines turn 
			for(int i = 0; i < 2; i++) {
				if(i == playerTurn) {
					writers[i].println("GO, " + players[(i + 1)%2]);
				}
				else {
					writers[i].println("WAIT, " + players[(i + 1)%2]);
				}
				writers[i].flush();
			}
			
			//carries out relaying messages until the game is over
			do{
				result = readers[playerTurn].nextLine();
				writers[(playerTurn+1)%2].println(result);
				writers[(playerTurn+1)%2].flush();
				
				//alternate turns
				if(playerTurn == 1) {
					playerTurn--;
				}
				else {
					playerTurn ++;
				}
			}while(!result.contains("over"));
			
			//Sends game over result to the loser
			writers[(playerTurn+1)%2].println(result);
			writers[(playerTurn+1)%2].flush();
			
			//Closes everything
			sock1.close();
			sock2.close();
			for(int i = 0; i < 2; i++) {
				writers[i].close();
				readers[i].close();
			}

		}catch(IOException e){
			e.printStackTrace();
		}
	}

	public static void main(String[] args){
		new Server();
	}
}
