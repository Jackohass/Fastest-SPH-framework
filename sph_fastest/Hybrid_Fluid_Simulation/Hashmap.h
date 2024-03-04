#ifndef __HASHMAP_H__
#define __HASHMAP_H__

#include <map>
#include <stdlib.h>

namespace Utilities
{
	template<class KeyType>
	inline unsigned int hashFunction(const KeyType &key)
	{
		return 0u;
	}


	template <class KeyType, class ValueType>
	class Hashmap
	{
	public:
		typedef typename std::map<unsigned int, ValueType> KeyValueMap;

	private:
		KeyValueMap **m_hashMap;
		unsigned int m_bucketCount;
		unsigned int m_moduloValue;

	protected:
		void init()
		{
			m_hashMap = new KeyValueMap*[m_bucketCount];
			for (unsigned int i=0; i < m_bucketCount; i++)
			{
				m_hashMap[i] = NULL;
			}
		}

		void cleanup()
		{
			if (m_hashMap)
			{
				for (unsigned int i=0; i < m_bucketCount; i++)
				{
					if (m_hashMap[i] != NULL)
					{
						m_hashMap[i]->clear();
						delete m_hashMap[i];
					}
				}
				delete [] m_hashMap;
				m_hashMap = NULL;
			}
		}

	public:
		Hashmap(const unsigned int bucketCount)
		{
			// Use a bucket count of 2^n => faster modulo
			unsigned int val = bucketCount;
			unsigned int powerOfTwo = 1u;
			while(powerOfTwo < val) 
				powerOfTwo <<= 1;
			m_bucketCount = powerOfTwo;
			m_moduloValue = m_bucketCount-1u;
			init();
		}

		~Hashmap()
		{
			cleanup();
		}

		void clear()
		{
			cleanup();
			init();
		}

		KeyValueMap* getKeyValueMap(const unsigned int index)
		{
			return m_hashMap[index];
		}

		void reset()
		{
			for (unsigned int i=0; i < m_bucketCount; i++)
			{
				if (m_hashMap[i] != NULL)
				{
					m_hashMap[i]->clear();
				}
			}
		}


		/** Return the bucket count.
		 */
		unsigned int bucket_count() const
		{	
			return m_bucketCount;
		}

		/** Find element. 
		 */
		ValueType* find(const KeyType &key)
		{
			const unsigned int hashValue = hashFunction<KeyType>(key);
			const unsigned int mapIndex = hashValue & m_moduloValue;
			if (m_hashMap[mapIndex] != NULL)
			{
				typename KeyValueMap::iterator &iter = (*m_hashMap[mapIndex]).find(hashValue);
				if (iter != (*m_hashMap[mapIndex]).end())
					return &iter->second;
			}
			return NULL;
		}

		/** Insert element. 
		 */
		void insert(const KeyType &key, const ValueType& value)
		{
			const unsigned int hashValue = hashFunction<KeyType>(key);
			const unsigned int mapIndex = hashValue & m_moduloValue;
			if (m_hashMap[mapIndex] == NULL)
			{
				m_hashMap[mapIndex] = new KeyValueMap();
			}
			(*m_hashMap[mapIndex])[hashValue] = value;
		}

		/** Remove the given element and return true, if the element was found. 
		 */
		void remove(const KeyType &key)
		{
			const unsigned int hashValue = hashFunction<KeyType>(key);
			const unsigned int mapIndex = hashValue & m_moduloValue;
			if (m_hashMap[mapIndex] != NULL)
			{
				m_hashMap[mapIndex]->erase(hashValue);
				if (m_hashMap[mapIndex]->size() == 0)
				{
					delete m_hashMap[mapIndex];
					m_hashMap[mapIndex] = NULL;
				}
			}
		}

		ValueType& operator[](const KeyType &key)
		{
			const int hashValue = hashFunction<KeyType>(key);
			const unsigned int mapIndex = hashValue & m_moduloValue;
			if (m_hashMap[mapIndex] == NULL)
			{
				m_hashMap[mapIndex] = new KeyValueMap();
			}
			return (*m_hashMap[mapIndex])[hashValue];
		}

		const ValueType& operator[](const KeyType &key) const
		{
			const unsigned int hashValue = hashFunction<KeyType>(key, m_bucketCount);
			const unsigned int mapIndex = hashValue & m_moduloValue;
			if (m_hashMap[mapIndex] == NULL)
			{
				m_hashMap[mapIndex] = new KeyValueMap();
			}
			return (*m_hashMap[mapIndex])[hashValue];
		}

		const ValueType* query(const KeyType &key) const
		{
			const unsigned int hashValue = hashFunction<KeyType>(key);
			const unsigned int mapIndex = hashValue & m_moduloValue;
			if (m_hashMap[mapIndex] == NULL)
			{
				return NULL;
			}
 			typename KeyValueMap::iterator &it = m_hashMap[mapIndex]->find(hashValue);
			if (it != m_hashMap[mapIndex]->end())
				return &it->second;
			return NULL;
		}

		ValueType* query(const KeyType &key) 
		{
			const unsigned int hashValue = hashFunction<KeyType>(key);
			const unsigned int mapIndex = hashValue & m_moduloValue;
			if (m_hashMap[mapIndex] == NULL)
			{
				return NULL;
			}
			const typename KeyValueMap::iterator &it = m_hashMap[mapIndex]->find(hashValue);
			if (it != m_hashMap[mapIndex]->end())
				return &it->second;
			return NULL;
		}
		
	};
}

#endif
