/*
 * Derek Hu and Ian Huang
 * Period 4
 * This program is the Client end of the network based Towering Nim game. It simulates a player and allows 
 * them to communicate with the server and play the game with another player.
 */

import java.util.*;
import java.net.*;

import javax.imageio.*;
import javax.swing.*;
import java.awt.*;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.awt.image.*;
import java.io.*;

public class Nim_Tower extends JFrame{

	private BufferedImage stoneCheckedImage;
	private BufferedImage stoneUnCheckedImage;

	private enum STATUS  {EMPTY,CHECKED,UNCHECKED};

	private PicPanel[][] allPanels;
	private ArrayList<PicPanel> selected;					//stones currently selected by the user
	private String[] playerNames;						//stores the names of the two players.  spot 1 is the opponent's name

	private int stonesLeft = 16;
	private boolean myTurn = false;
	private PrintWriter toServer;
	private Socket theSocket;
	private Scanner fromServer;
	private final String SERVER_IP = "10.104.13.74";
	private final int SERVER_PORT = 4242;

	public Nim_Tower(String IP, int port){

		try {
			stoneCheckedImage = ImageIO.read(new File("stone_checked.jpg"));
			stoneUnCheckedImage = ImageIO.read(new File("stone_unchecked.jpg"));
		} catch (IOException ioe) {
			JOptionPane.showMessageDialog(null, "Could not read in the pic");
			System.exit(0);
		}

		selected = new ArrayList<PicPanel>();
		playerNames = new String[2];

		setSize(715,750);
		setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		getContentPane().setBackground(Color.black);

		//JPanel container = new JPanel()
		setLayout(new GridLayout(7,7,2,2));

		allPanels = new PicPanel[7][7];
		for(int row = 0; row < 7; row++){
			for(int col = 0; col < 7; col++){
				allPanels[row][col] = new PicPanel(row,col);
				add(allPanels[row][col]);
			}
		}

		//YOUR CODE GOES HERE - PLACE STONES ON THE GRID
		//adds stones to the grid
		for (int row = 4; row >= 1; row--) {
			for (int col = 4 - row; col < allPanels.length - (4 - row); col++) {
				allPanels[row][col].addStone();
			}
		}

		//prompts the users for their name 
		playerNames[0] = JOptionPane.showInputDialog(null,"Enter player your name");

		//sets up socket and writer
		try {
			theSocket = new Socket(SERVER_IP, SERVER_PORT);
			toServer = new PrintWriter(theSocket.getOutputStream());
			
			//sends name to server
			toServer.println(playerNames[0]);
			toServer.flush();
			
			//sets up scanner
			fromServer = new Scanner(theSocket.getInputStream());
			String status = fromServer.nextLine();
			
			//determines turn
			if (status.indexOf("GO") != -1) 
				myTurn = true;

			playerNames[1] = status.substring(status.indexOf(",") + 2);
		} catch(IOException e) {
			e.printStackTrace();
		}
		updateTitle();

		Thread t = new Thread(new IncomingReader());
		t.start();
		setVisible(true);
	}

	//updates title based on status of game
	private void updateTitle() {
		//game over
		if (stonesLeft == 0) {
			if (myTurn)
				setTitle("GAME IS OVER " + playerNames[1] + " WON.");
			else 
				setTitle("GAME IS OVER " + playerNames[0] + " WON.");
		}
		else {
			if (myTurn) 
				setTitle("Nim - " + playerNames[1] + "'s turn");
			else if (!myTurn)
				setTitle("Nim - " + playerNames[0] + "'s turn");
		}
	}

	private void sortSelectedPanels(){
		Collections.sort(selected);
	}

	class PicPanel extends JPanel implements MouseListener, Comparable<PicPanel>{

		private int row;
		private int col;
		private STATUS status;

		public PicPanel(int r, int c){
			row = r;
			col = c;
			status = STATUS.EMPTY;

		}		

		//draws the cell have a white background or one of the two images
		public void paintComponent(Graphics g){
			super.paintComponent(g);

			if(status == STATUS.EMPTY)
				setBackground(Color.white);
			else if(status == STATUS.CHECKED)
				g.drawImage(stoneCheckedImage, 0,0,this);
			else
				g.drawImage(stoneUnCheckedImage, 0, 0, this);
		}

		//makes this panel contain a stone
		public void addStone(){
			status = STATUS.UNCHECKED;
			this.addMouseListener(this);
			this.repaint();
		}

		//highlights a stone in green to indicate it has been selected
		//adds it to the selected AL
		public void selectStone(){
			if(status == STATUS.UNCHECKED){
				status = STATUS.CHECKED;
				selected.add(this);
				this.repaint();
			}
		}

		//turns a stone's background back to white
		//removes it from the selected AL
		public void unCheckStone(){
			if(status == STATUS.CHECKED){
				status = STATUS.UNCHECKED;
				selected.remove(this);
				this.repaint();
			}
		}

		//called when a stone has been removed by a player
		//prevents this cell from ever being selected again.
		public void removeStone(){
			if(status != STATUS.EMPTY){
				status = STATUS.EMPTY;
				this.removeMouseListener(this);
				this.repaint();
			}
		}

		public boolean equals(Object o){
			if(!(o instanceof PicPanel))
				return false;

			PicPanel other = (PicPanel)o;
			return row == other.row && col == other.col;
		}
		
		//prints whose turn it is
		private String printTurn() {
			if (myTurn) 
				return playerNames[0] + "'s turn.";
			else 
				return playerNames[1] + "'s turn.";
		}

		//creates pop-up of text
		private void displayMessage(String text) {
			JOptionPane.showMessageDialog(null, text);
		}

		//reacts to the user either clicking the left or right mouse button
		public void mouseClicked(MouseEvent arg0) {
			//Checks if it's their turn, if there are stones left
			if (myTurn && stonesLeft > 0) {
				//on left mouse click checks if a stone should be selected or unselected
				if(arg0.getButton() == MouseEvent.BUTTON1) {
					if (status == STATUS.UNCHECKED) 
						selectStone();
					else 
						unCheckStone();
				}
				//on right mouse click, checks if all stones selected are valid
				//right mouse click
				else if(arg0.getButton() == MouseEvent.BUTTON3) {
					//nothing selected
					if (selected.size() == 0) 
						displayMessage("No stones selected!\nStill " + printTurn());
					else {
						//sort panels and check gap
						sortSelectedPanels();

						//check valid stones selected 
						PicPanel cur = selected.get(0);
						PicPanel next = selected.get(selected.size() - 1);

						//check same row
						if (cur.row != next.row) {
							displayMessage("Stones in different rows!\nStill " + printTurn());
							return;
						}

						//check gap
						else if (next.compareTo(cur) != selected.size() - 1) {
							displayMessage("Stones have a gap!\nStill " + printTurn());
							return;
						}

						stonesLeft -= selected.size();
						String toSend = "";

						//removes stones 
						for (PicPanel p: selected) {
							p.removeStone();
							toSend += p.row + "," + p.col + ";";
						}
						
						//sends to server what was removed
						toServer.println(toSend);
						toServer.flush();
						selected.clear();

						//updates myTurn/title to indicate whose turn it is or if game is over
						myTurn = false;
						updateTitle();
					}
				}
			}
		}

		//for debugging purposes
		public String toString(){
			return "("+row+","+col+")";
		}

		public int compareTo(PicPanel other){
			int rowDiff = this.row - other.row;

			if(rowDiff == 0)
				return this.col - other.col;

			return rowDiff;
		}

		//DO NOT IMPLEMENTS THESE FOUR METHODS
		@Override
		public void mouseEntered(MouseEvent arg0) {
			// TODO Auto-generated method stub

		}

		@Override
		public void mouseExited(MouseEvent arg0) {
			// TODO Auto-generated method stub

		}

		@Override
		public void mousePressed(MouseEvent arg0) {
			// TODO Auto-generated method stub

		}

		@Override
		public void mouseReleased(MouseEvent arg0) {
			// TODO Auto-generated method stub

		}
	}

	public class IncomingReader implements Runnable{
		public void run() {
			while(fromServer.hasNextLine()) {
				String line = fromServer.nextLine();
				String[] moves = line.split(";");
			
				//ends game
				if (line.equals("over")) 
					closeHelper();
				
				//removes stones that the other player removed
				if (stonesLeft != 0) {
					//removes each stone
					for (int i = 0; i < moves.length; i++) {
						String[] remove = moves[i].split(",");
						allPanels[Integer.parseInt(remove[0])][Integer.parseInt(remove[1])].removeStone();
						stonesLeft--;
					}
					myTurn = true;
					
					//sends over if no more stones
					if (stonesLeft == 0) {
						toServer.println("over");
						toServer.flush();	
						closeHelper();
					}
				}
				
				//updates myTurn and title (keep going or the game is over)
				updateTitle();
			}
		}
		
		//closes the socket and writer
		private void closeHelper() {
			try {
				toServer.close();
				theSocket.close();
			} catch(IOException e) {
				e.printStackTrace();
			}
		}
	}

	public static void main(String[] args){
		new Nim_Tower("IP ADDRESS GOES HERE",4242);
	}
}