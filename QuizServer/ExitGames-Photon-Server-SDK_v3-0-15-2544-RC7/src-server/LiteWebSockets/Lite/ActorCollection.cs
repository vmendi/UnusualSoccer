// --------------------------------------------------------------------------------------------------------------------
// <copyright file="ActorCollection.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   A collection for <see cref="Actor" />s.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Lite
{
    using System.Collections;
    using System.Collections.Generic;
    using System.Linq;

    /// <summary>
    /// A collection for <see cref="Actor"/>s.
    /// </summary>
    public class ActorCollection : ICollection<Actor>
    {
        /// <summary>List of Actors in this Room.</summary>
        private readonly List<Actor> actorList;

        /// <summary>
        /// Initializes a new instance of the <see cref="ActorCollection"/> class.
        /// </summary>
        public ActorCollection()
        {
            this.actorList = new List<Actor>();
        }

        /// <summary>
        /// Gets the number of actors contained in the <see cref="ActorCollection"/>.
        /// </summary>
        public int Count
        {
            get
            {
                return this.actorList.Count;
            }
        }

        /// <summary>
        /// Gets a value indicating whether the <see cref="ActorCollection"/> is read-only.
        /// </summary>
        /// <returns>
        /// true if the <see cref="ActorCollection"/> is read-only; otherwise, false.
        /// </returns>
        public bool IsReadOnly
        {
            get
            {
                return false;
            }
        }

        /// <summary>
        /// Gets the <see cref="Actor"/> at the specified index.
        /// </summary>
        /// <param name="index">The index.</param>
        public Actor this[int index]
        {
            get
            {
                return this.actorList[index];
            }
        }

        /// <summary>
        /// Gets an actor by the actor number.
        /// </summary>
        /// <param name="actorNumber">
        /// The actor number.
        /// </param>
        /// <returns>
        /// Return the actor with the specified actor number if found.
        /// If no actor with the specified actor number exits null will be returned.
        /// </returns>
        public Actor GetActorByNumber(int actorNumber)
        {
            foreach (Actor actor in this.actorList)
            {
                if (actor.ActorNr == actorNumber)
                {
                    return actor;
                }
            }

            return null;
        }

        /// <summary>
        /// Gets an actor by a specified peer.
        /// </summary>
        /// <param name="peer">
        /// The peer.
        /// </param>
        /// <returns>
        /// Returns the actor for the specified peer or null 
        /// if no actor for the specified peer was found.
        /// </returns>
        public Actor GetActorByPeer(LitePeer peer)
        {
            foreach (Actor actor in this.actorList)
            {
                if (actor.Peer == peer)
                {
                    return actor;
                }
            }

            return null;
        }

        /// <summary>
        /// Gets the actor numbers of all actors in this instance as an array.
        /// </summary>
        /// <returns>
        /// Array of the actor numbers.
        /// </returns>
        public int[] GetActorNumbers()
        {
            var actorNrs = new int[this.Count];

            for (int i = 0; i < this.Count; i++)
            {
                actorNrs[i] = this.actorList[i].ActorNr;
            }

            return actorNrs;
        }

        /// <summary>
        /// Gets a list of actors in the room exluding a specified actor.
        /// This method can be used to get the actor list for an event, 
        /// where the actor causing the event should not be notified.
        /// </summary>
        /// <param name="actorToExclude">
        /// The actor to exclude.
        /// </param>
        /// <returns>
        /// the actors without <paramref name="actorToExclude"/>
        /// </returns>
        public List<Actor> GetExcludedList(Actor actorToExclude)
        {
            var result = new List<Actor>(this.Count);
            result.AddRange(this.actorList.Where(actor => actor != actorToExclude));
            return result;
        }

        /// <summary>
        /// Removes the actor for a a specified peer.
        /// </summary>
        /// <param name="peer">
        /// The peer.
        /// </param>
        /// <returns>
        /// The <see cref="Actor"/> removed or <c>null</c> if no actor for the specified peer exists.
        /// </returns>
        public Actor RemoveActorByPeer(LitePeer peer)
        {
            Actor actor = this.GetActorByPeer(peer);
            if (actor == null)
            {
                return null;
            }

            this.Remove(actor);
            return actor;
        }

        #region Implemented Interfaces

        #region ICollection<Actor>

        /// <summary>
        /// Adds an actor to the collection.
        /// </summary>
        /// <param name="actor">
        /// The <see cref="Actor"/> to add.
        /// </param>
        public void Add(Actor actor)
        {
            this.actorList.Add(actor);
        }

        /// <summary>
        /// Removes all items from the collection.
        /// </summary>
        public void Clear()
        {
            this.actorList.Clear();
        }

        /// <summary>
        /// Determines whether the collection contains a specific <see cref="Actor"/>.
        /// </summary>
        /// <param name="actor">
        /// The actor to locate in this collection.
        /// </param>
        /// <returns>
        /// true if the actor is found; otherwise, false.
        /// </returns>
        public bool Contains(Actor actor)
        {
            return this.actorList.Contains(actor);
        }

        /// <summary>
        /// Copies the elements of the <see cref="ActorCollection"/> to an Array, starting at a particular Array index.
        /// </summary>
        /// <param name="array">
        /// The one-dimensional <see cref="System.Array"/> that is the destination of the elements copied from <see cref="ActorCollection"/>. 
        /// The <see cref="System.Array"/> must have zero-based indexing.
        /// </param>
        /// <param name="arrayIndex">
        /// The zero-based index in <paramref name="array"/> at which copying begins.
        /// </param>
        /// <exception cref="System.ArgumentNullException">
        /// <paramref name="array"/> is null.
        /// </exception>
        /// <exception cref="System.ArgumentOutOfRangeException">
        /// <paramref name="arrayIndex"/> is less than 0.
        /// </exception>
        /// <exception cref="System.ArgumentException">
        /// <paramref name="array"/> is multidimensional.
        ///     -or-
        ///     <paramref name="arrayIndex"/> is equal to or greater than the length of <paramref name="array"/>.
        ///     -or-
        ///     The number of elements in the source <see cref="ActorCollection"/> is greater 
        ///     than the available space from <paramref name="arrayIndex"/> to the end of the 
        ///     destination <paramref name="array"/>.
        ///     -or-
        ///     Type <see cref="ActorCollection"/> cannot be cast automatically to the type of the destination <paramref name="array"/>.
        /// </exception>
        public void CopyTo(Actor[] array, int arrayIndex)
        {
            this.actorList.CopyTo(array, arrayIndex);
        }

        /// <summary>
        /// Removes a specified actor from this collection.
        /// </summary>
        /// <param name="actor">
        /// The actor to remove.
        /// </param>
        /// <returns>
        /// True if <paramref name="actor"/> was successfully removed; otherwise (if not found) false. 
        /// </returns>
        public bool Remove(Actor actor)
        {
            return this.actorList.Remove(actor);
        }

        #endregion

        #region IEnumerable

        /// <summary>
        /// Returns an <see cref="IEnumerator"/>.
        /// </summary>
        /// <returns>
        /// the actor enumerator
        /// </returns>
        IEnumerator IEnumerable.GetEnumerator()
        {
            return this.actorList.GetEnumerator();
        }

        #endregion

        #region IEnumerable<Actor>

        /// <summary>
        /// Returns an <see cref="IEnumerator{Actor}"/>.
        /// </summary>
        /// <returns>
        /// the actor enumerator
        /// </returns>
        public IEnumerator<Actor> GetEnumerator()
        {
            return this.actorList.GetEnumerator();
        }

        #endregion

        #endregion
    }
}