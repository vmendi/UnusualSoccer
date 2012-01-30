namespace Lite.Caching
{
    using System.Collections;
    using System.Collections.Generic;

    using Lite.Events;
    using Lite.Operations;

    public class RoomEventCache : IEnumerable<CustomEvent>
    {
        private readonly List<CustomEvent> cachedRoomEvents = new List<CustomEvent>();

        public void AddEvent(CustomEvent customeEvent)
        {
            this.cachedRoomEvents.Add(customeEvent);
        }

        public void RemoveEvents(RaiseEventRequest raiseEventRequest)
        {
            for (int i = this.cachedRoomEvents.Count - 1; i >= 0; i--)
            {
                var cachedEvent = this.cachedRoomEvents[i];

                if (raiseEventRequest.EvCode != 0 && cachedEvent.Code != raiseEventRequest.EvCode)
                {
                    continue;
                }

                if (raiseEventRequest.Actors != null && raiseEventRequest.Actors.Length > 0)
                {
                    bool actorMatch = false;
                    for (int a = 0; a < raiseEventRequest.Actors.Length; a++)
                    {
                        if (cachedEvent.ActorNr != raiseEventRequest.Actors[a])
                        {
                            continue;
                        }

                        actorMatch = true;
                        break;
                    }

                    if (actorMatch == false)
                    {
                        continue;
                    }
                }
                
                if (raiseEventRequest.Data == null)
                {
                    this.cachedRoomEvents.RemoveAt(i);
                    continue;
                }

                if (Compare(raiseEventRequest.Data, cachedEvent.Data))
                {
                    this.cachedRoomEvents.RemoveAt(i);
                }
            }
        }

        #region IEnumerable<CustomEvent> Members

        public IEnumerator<CustomEvent> GetEnumerator()
        {
            return this.cachedRoomEvents.GetEnumerator();
        }

        #endregion

        #region IEnumerable Members

        IEnumerator IEnumerable.GetEnumerator()
        {
            return this.cachedRoomEvents.GetEnumerator();
        }

        #endregion

        private static bool Compare(Hashtable h1, Hashtable h2)
        {
            foreach (DictionaryEntry entry in h1)
            {
                if (h2.ContainsKey(entry.Key) == false)
                {
                    return false;
                }

                object cachedParam = h2[entry.Key];
                if (entry.Value == null && cachedParam != null)
                {
                    return false;
                }

                if (cachedParam == null)
                {
                    return false;
                }

                if (entry.Value.Equals(cachedParam) == false)
                {
                    return false;
                }
            }

            return true;
        }
    }
}
