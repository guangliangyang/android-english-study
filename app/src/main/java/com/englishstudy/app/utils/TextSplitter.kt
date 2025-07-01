package com.englishstudy.app.utils

object TextSplitter {
    
    /**
     * Split text into sentences using common sentence delimiters
     * @param text The input text to split
     * @return List of sentences with proper punctuation
     */
    fun splitIntoSentences(text: String): List<String> {
        if (text.isBlank()) return emptyList()
        
        // Improved sentence splitting approach
        // First split by sentence-ending punctuation followed by whitespace or end of string
        val sentences = mutableListOf<String>()
        
        // More robust regex that handles various cases
        val sentenceRegex = Regex("[.!?]+\\s*")
        val parts = text.split(sentenceRegex)
        
        // Find all punctuation matches to reconstruct sentences with proper endings
        val punctuationMatches = sentenceRegex.findAll(text).map { it.value.trim() }.toList()
        
        for (i in parts.indices) {
            val part = parts[i].trim()
            if (part.isNotEmpty()) {
                val sentence = if (i < punctuationMatches.size) {
                    // Add back the punctuation
                    val punct = punctuationMatches[i]
                    if (punct.isNotEmpty()) "$part${punct.first()}" else "$part."
                } else {
                    // Last part without punctuation, add period
                    if (part.endsWith(".") || part.endsWith("!") || part.endsWith("?")) part else "$part."
                }
                sentences.add(sentence)
            }
        }
        
        // If regex splitting didn't work well, fall back to simple approach
        if (sentences.isEmpty() && text.isNotBlank()) {
            sentences.add(if (text.endsWith(".") || text.endsWith("!") || text.endsWith("?")) text else "$text.")
        }
        
        return sentences
    }
    
    /**
     * Clean and normalize text before splitting
     * @param text Raw input text
     * @return Cleaned text ready for sentence splitting
     */
    fun cleanText(text: String): String {
        return text
            .replace(Regex("\\s+"), " ") // Replace multiple spaces with single space
            .replace(Regex("\\n+"), " ") // Replace newlines with spaces
            .trim()
    }
    
    /**
     * Split text into sentences and clean them
     * @param text Raw input text
     * @return List of clean sentences
     */
    fun splitAndClean(text: String): List<String> {
        val cleanedText = cleanText(text)
        return splitIntoSentences(cleanedText)
    }
}