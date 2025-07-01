package com.englishstudy.app.adapter

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.englishstudy.app.R
import com.englishstudy.app.data.TextEntry

class TextEntryAdapter(
    private val onItemClick: (TextEntry) -> Unit,
    private val onPlayClick: (TextEntry) -> Unit,
    private val onItemLongClick: (TextEntry) -> Unit
) : ListAdapter<TextEntry, TextEntryAdapter.ViewHolder>(DiffCallback()) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_text_entry, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.bind(getItem(position))
    }

    inner class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val titleText: TextView = itemView.findViewById(R.id.titleText)
        private val contentPreview: TextView = itemView.findViewById(R.id.contentPreview)
        private val wordCountText: TextView = itemView.findViewById(R.id.wordCountText)
        private val durationText: TextView = itemView.findViewById(R.id.durationText)
        private val playButton: ImageView = itemView.findViewById(R.id.playButton)

        fun bind(entry: TextEntry) {
            titleText.text = entry.title
            contentPreview.text = entry.content
            wordCountText.text = "词汇量: ${entry.wordCount}"
            durationText.text = entry.estimatedDuration ?: "未知时长"

            itemView.setOnClickListener {
                onItemClick(entry)
            }
            
            itemView.setOnLongClickListener {
                onItemLongClick(entry)
                true
            }

            playButton.setOnClickListener {
                onPlayClick(entry)
            }
            
            playButton.isEnabled = !entry.audioFilePath.isNullOrEmpty()
        }
    }

    private class DiffCallback : DiffUtil.ItemCallback<TextEntry>() {
        override fun areItemsTheSame(oldItem: TextEntry, newItem: TextEntry): Boolean {
            return oldItem.id == newItem.id
        }

        override fun areContentsTheSame(oldItem: TextEntry, newItem: TextEntry): Boolean {
            return oldItem == newItem
        }
    }
}