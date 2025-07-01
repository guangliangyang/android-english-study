package com.englishstudy.app.adapter

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.englishstudy.app.R

class SentenceAdapter(
    private val sentences: List<String>,
    private val onSentenceClick: (Int) -> Unit
) : RecyclerView.Adapter<SentenceAdapter.SentenceViewHolder>() {
    
    private var currentPlayingIndex = -1
    
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): SentenceViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_sentence, parent, false)
        return SentenceViewHolder(view)
    }
    
    override fun onBindViewHolder(holder: SentenceViewHolder, position: Int) {
        holder.bind(sentences[position], position, currentPlayingIndex == position)
    }
    
    override fun getItemCount(): Int = sentences.size
    
    fun setCurrentPlayingIndex(index: Int) {
        val oldIndex = currentPlayingIndex
        currentPlayingIndex = index
        
        // Update old highlighted item
        if (oldIndex != -1) {
            notifyItemChanged(oldIndex)
        }
        
        // Update new highlighted item
        if (index != -1) {
            notifyItemChanged(index)
        }
    }
    
    inner class SentenceViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val sentenceText: TextView = itemView.findViewById(R.id.sentenceText)
        
        fun bind(sentence: String, position: Int, isPlaying: Boolean) {
            sentenceText.text = sentence
            
            // Set selection state for highlighting
            itemView.isSelected = isPlaying
            
            // Add click listener
            itemView.setOnClickListener {
                onSentenceClick(position)
            }
            
            // Add margin between sentences
            val params = itemView.layoutParams as RecyclerView.LayoutParams
            params.bottomMargin = 8
            itemView.layoutParams = params
        }
    }
}