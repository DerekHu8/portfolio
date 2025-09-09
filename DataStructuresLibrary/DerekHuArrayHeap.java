/*
 * Derek Hu
 * Period 4
 * ArrayHeap uses an array based heap to simulate a priority queue. It allows for adding items, removing the 
 * highest priority item, and peeking. 
 */

import java.util.*;

public class DerekHuArrayHeap<E extends Comparable<E>> implements PriorityQueue<E> {
	
	private E[] data;
	private int numElements;
	
	public DerekHuArrayHeap() {
		data = (E[]) new Comparable[10];
		numElements = 0;
	}
	
	//checks if array has active items
	public boolean isEmpty() {
		return numElements == 0;
	}
	
	//inserts and reheaps up for correct priority order
	public void add(E item) {
		//array is full
		if (numElements == data.length) {
			E[] resize = (E[]) new Object[data.length * 2];
			
			//readds everything
			for (int i = 0; i < numElements; i++)
				resize[i] = data[i];	
			data = resize;
		}
		
		data[numElements] = item;
		
		int current = numElements;
		int next = (current - 1) / 2;
		
		//reheaping up
		while (next >= 0 && data[current].compareTo(data[next]) < 0) {
			//switches two data
			E toMove = data[next];
			data[next] = data[current];
			data[current] = toMove;
			
			current = next;
			next = (current - 1) / 2;
		}
		numElements++;
	}
	
	//removes item of highest priority from queue
	public E remove() {
		E toReturn = peek();
		numElements--;
		
		//still items in queue
		if (!isEmpty()) {
			data[0] = data[numElements];
			
			int current = 0;
			int left = current * 2 + 1;
			int right = current * 2 + 2;
			
			//in bounds
			while (left < numElements) {
				int priority = left;
				
				//right higher priority than left
				if (right < numElements && data[right].compareTo(data[left]) < 0)
					priority = right;
				
				//current is lower priority than subtree
				if (data[current].compareTo(data[priority]) > 0) {
					//switches two data
					E toMove = data[current];
					data[current] = data[priority];
					data[priority] = toMove;
					
					current = priority;
					left = current * 2 + 1;
					right = current * 2 + 2;
				}
				//in right spot
				else 
					left = numElements;
			}
		}
		return toReturn;
	}
	
	//returns item of highest priority
	public E peek() {
		if (isEmpty())
			throw new NoSuchElementException();
		return data[0];
	}
}