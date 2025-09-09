/*
 * Derek Hu and Jiali Wei
 * Period 4
 * This program acts as the server to transmit messages between clients in a chatting interface.
 * Will accept infinite clients and send messages between everyone.
 */

import java.io.*;
import java.net.*;
import java.util.*;

public class ChatServer {
	private ArrayList<PrintWriter> clientOutputStreams;  
	private String secretKey;

	public  ChatServer() {
		//randomly generated key
		secretKey = (int)(Math.random() * 100000) + "";
		clientOutputStreams = new ArrayList<PrintWriter>();
		try {
			ServerSocket server = new ServerSocket(4242);
			
			//infinitely accepts and initializes
			while (true) {
				Socket theSock = server.accept();
				ClientHandler threadJob = new ClientHandler(theSock);
				Thread newThread = new Thread(threadJob);
				newThread.start();
			}
		} catch(IOException e) {
			e.printStackTrace();
		}
	}

	//writes the message to every socket
	public void tellEveryone(String message) {
		//writes to all clients
		for (PrintWriter clients : clientOutputStreams) {
			clients.println(message);
			clients.flush();
		}
	}
	
	//makes a listener for each of the clients
	public class ClientHandler implements Runnable {

		private Scanner reader;
		private Socket sock;
		private PrintWriter theWriter;

		public ClientHandler(Socket clientSocket) {
			try {
				//initializes
				sock = clientSocket;
				reader = new Scanner(sock.getInputStream());
				theWriter = new PrintWriter(sock.getOutputStream());
				
				synchronized(clientOutputStreams) {
					clientOutputStreams.add(theWriter);
				}
				
				//sends key
				theWriter.println(secretKey);
				theWriter.flush();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		
		//transmits messages to all clients
		public void run() {
			//looking for message
			while (reader.hasNextLine()) {
				String message = reader.nextLine();
				tellEveryone(message);
			}
			closeConnections();
		}
		
		//closes all connections for client
		private void closeConnections() {
			try {
				synchronized(clientOutputStreams) {
					reader.close();
					theWriter.close();
					sock.close();
					clientOutputStreams.remove(theWriter);
				}
			} catch(IOException e) {
				e.printStackTrace();
			}
		}
	}

	public static void main(String[] args) {
		new ChatServer();
	}
}