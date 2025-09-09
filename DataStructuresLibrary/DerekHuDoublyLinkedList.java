/*
 * Derek Hu
 * Period 6
 * This class simulates a Doubly Linked List and allows for many common list methods to be 
 * enacted onto our Doubly Linked List. A Doubly Linked List is where there is a forward and backward
 * connection to each node.
 */

import java.util.*;

public class DerekHuDoublyLinkedList<E> {
	private ListNode front;
	private ListNode end; 
	private int numElements;
	
	public boolean isEmpty() {
		return front == null;
	}
	
	//adds a node to the front of the list
	public void addFront(E item) {
		
		//empty list
		if (isEmpty()) {
			front = new ListNode(null, item, null);
			end = front;
		}
		//items in list
		else {
			front = new ListNode(null, item, front);
			front.next.previous = front;
		}
		numElements++;
	}
	
	//adds a node after a specified index
	public void addAfter(int index, E item) {
		inBound(index);
		
		//adding after last index
		if (index == numElements - 1) {
			addLast(item);
		}
		else {
			//iterating up to index and adding
			ListNode current = front;
			for (int i = 0; i < index; i++) {
				current = current.next;
			}
			
			current.next = new ListNode(current, item, current.next);
			numElements++;
		}
	}
	
	//adds a node at the end of the list
	public void addLast(E item) {
		
		//adds in if empty
		if (isEmpty()) {
			addFront(item);
		}
		else {
			//adds to end
			end = new ListNode(end, item, null);
			end.previous.next = end;
			numElements++;
		}
	}
	
	//removes a specified item
	public void remove(E item) {
		
		if (!isEmpty()) {			
			//remove first item if equal
			if (front.data.equals(item)) {
				removeFirst();
			}
			//last item if equal
			else if (end.data.equals(item)) {
				removeLast();
			}
			else {
				ListNode current = front;
				
				//searches until first occurrence is found and removes
				while (current.next != null) {
					if (current.next.data.equals(item)) {
						ListNode toRem = current.next;
						current.next = current.next.next;
						current.next.previous = null;
						toRem.next = null;
						toRem.next.previous = null;
						numElements--;
						return;
					}
					current = current.next;
				}
				throw new NoSuchElementException("The item was not found");
			}
		}
	}
	
	//removes the first node
	public void removeFirst() {
		
		if (!isEmpty()) {
			//only one node
			if (numElements == 1) {
				front = null; 
				end = null;
			}
			else {
				//severs connections
				ListNode toRem = front;
				front = front.next;
				front.previous = null;
				toRem.next = null;
			}
			numElements--;
		}
	}	
	
	public void removeLast() {
		
		if (!isEmpty()) {
			//only one node
			if (numElements == 1) {
				front = null; 
				end = null;
			}
			else {
				//severs connections
				ListNode toRem = end;
				end = end.previous;
				end.next = null;
				toRem.previous = null;
			}
			numElements--;
		}
	}
	
	//number of nodes in list
	public int size() {
		return numElements;
	}
	
	//gives data from node at a certain index
	public E get(int index) {
		inBound(index);
		ListNode current = stepToIndex(index);
		return current.data;
	}
	
	//changes the data on a node at a certain index
	public void set(int index, E item) {
		inBound(index);
		ListNode current = stepToIndex(index);
		current.data = item;
	}
	
	//displays list front to end
	public void printForward() {
		ListNode current = front;
		
		while (current != null) {
			 System.out.println(current.data);
			 current = current.next;
		}
	}
	
	//displays list end to front
	public void printBackward() {
		ListNode current = end;
		
		while (current != null) {
			System.out.println(current.data);
			current = current.previous;
		}
	}
	
	//checks the given index is in the list
	private void inBound(int index) {
		if (index < 0 || index >= numElements) {
			throw new IndexOutOfBoundsException("Index is not in bounds");
		}
	}
	
	//determines whether to start from front or end and then iterates to certain index
	private ListNode stepToIndex(int index) {
		ListNode current = front;
		
		//index further than halfway point
		if (index > numElements / 2) {
			current = end;
			
			//count from end to index
			for (int i = numElements - 1; i > index; i--) {
				current = current.previous;
			}
		}
		//index before halfway
		else {
			//counts from front to index
			for (int i = 0; i < index; i++) {
				current = current.next;
			}
		}
		return current;
	}
	
	//represents each spot in the linked list
	public class ListNode {
		private E data;
		private ListNode next;
		private ListNode previous;
		
		public ListNode(ListNode p, E d, ListNode n) {
			previous = p;
			data = d;
			next = n;
		}
	}
}