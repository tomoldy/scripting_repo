unit tpa;
{==============================================================================]
  Copyright:
   - Copyright (c) 2016, Jarl `slacky` Holta
   - Raymond van Venetië and Merlijn Wajer
  License: GNU General Public License (https://www.gnu.org/licenses/gpl-3.0)
  Links:
   - https://github.com/Torwent/Simba/blob/simba1400/Source/MML/simba.tpa.pas
   - https://github.com/Villavu/Simba/blob/simba2000/Source/simba.vartype_pointarray.pas
   - https://pastebin.com/8hxwnptq
[==============================================================================}
{$mode objfpc}{$H+}

interface

uses sysutils, types;

function TPAMatrix(tpa: TPointArray): T2DBoolArray;

type TNode = record Pt: TPoint; Weight: Int32; end;
type TQueue = array of TNode;

procedure _SiftDown(var queue: TQueue; startpos, pos: Int32);
procedure _SiftUp(var queue: TQueue; pos: Int32);

type TAStarNodeData = record Parent: TPoint; Open, Closed: Boolean; ScoreA, ScoreB: Int32; end;
type TAStarData = array of array of TAStarNodeData;

procedure _Push(var queue: TQueue; node: TNode; var data: TAStarData; var size: Int32);
function _Pop(var queue: TQueue; var data: TAStarData; var size: Int32): TNode;
function _BuildPath(start, goal: TPoint; data: TAStarData; offset: TPoint): TPointArray;

function AStarTPAEx(tpa: TPointArray; out paths: T2DFloatArray; start, goal: TPoint; diagonalTravel: Boolean): TPointArray;
function AStarTPA(tpa: TPointArray; start, goal: TPoint; diagonalTravel: Boolean): TPointArray; overload;

implementation

uses Math;


function TPAMatrix(tpa: TPointArray): T2DBoolArray;
var
  b: TBox;
  p: TPoint;
begin
  b := GetTPABounds(tpa);
  SetLength(Result, b.Y2+1, b.X2+1);
  for p in tpa do Result[p.Y, p.X] := True;
end;


//AStar
procedure _SiftDown(var queue: TQueue; startpos, pos: Int32);
var
  parentpos: Int32;
  parent,newitem: TNode;
begin
  newitem := queue[pos];
  while pos > startpos do
  begin
    parentpos := (pos - 1) shr 1;
    parent := queue[parentpos];
    if (newitem.Weight < parent.Weight) then
    begin
      queue[pos] := parent;
      pos := parentpos;
      continue;
    end;
    Break;
  end;
  queue[pos] := newitem;
end;

procedure _SiftUp(var queue: TQueue; pos: Int32);
var
  endpos, startpos, childpos, rightpos: Int32;
  newitem: TNode;
begin
  endpos := Length(queue);
  startpos := pos;
  newitem := queue[pos];
  // Move the smaller child up until hitting a leaf.
  childpos := 2 * pos + 1;    // leftmost child
  while (childpos < endpos) do
  begin
    // Set childpos to index of smaller child.
    rightpos := childpos + 1;
    if (rightpos < endpos) and (queue[childpos].Weight >= queue[rightpos].Weight) then
      childpos := rightpos;
    // Move the smaller child up.
    queue[pos] := queue[childpos];
    pos := childpos;
    childpos := 2 * pos + 1;
  end;
  // This (`pos`) node/leaf is empty. So we can place "newitem" in here, then
  // push it up to its final place (by sifting its parents down).
  queue[pos] := newitem;
  _SiftDown(queue, startpos, pos);
end;

procedure _Push(var queue: TQueue; node: TNode; var data: TAStarData; var size: Int32);
var
  i: Int32;
begin
  i := Length(queue);
  SetLength(queue, i + 1);
  queue[i] := node;
  _SiftDown(queue, 0, i);
  data[node.Pt.Y, node.Pt.X].Open := True;
  Inc(size);
end;

function _Pop(var queue: TQueue; var data: TAStarData; var size: Int32): TNode;
var
  node: TNode;
begin
  node := queue[High(queue)];
  SetLength(queue, High(queue));

  if Length(queue) > 0 then
  begin
    Result := queue[0];
    queue[0] := node;
    _SiftUp(queue, 0);
  end
  else
    Result := node;

  data[Result.Pt.Y, Result.Pt.X].Open := False;
  data[Result.Pt.Y, Result.Pt.X].Closed := True;
  Dec(size);
end;

function _BuildPath(start, goal: TPoint; data: TAStarData; offset: TPoint): TPointArray;
var
  tmp: TPoint;
  len: Int32 = 0;
begin
  tmp := goal;

  while tmp <> start do
  begin
    Inc(len);
    SetLength(Result, len);
    Result[len-1].X := tmp.X + offset.X;
    Result[len-1].Y := tmp.Y + offset.Y;
    tmp := data[tmp.Y, tmp.X].Parent;
  end;

  Inc(len);
  SetLength(Result, len);
  Result[len-1].X := tmp.X + offset.X;
  Result[len-1].Y := tmp.Y + offset.Y;
  TPAReverse(Result);
end;


function AStarTPAEx(tpa: TPointArray; out paths: T2DFloatArray; start, goal: TPoint; diagonalTravel: Boolean): TPointArray;
const
  OFFSETS: array[0..7] of TPoint = ((X:0; Y:-1),(X:-1; Y:0),(X:1; Y:0),(X:0; Y:1),(X:1; Y:-1),(X:-1; Y:1),(X:1; Y:1),(X:-1; Y:-1));
var
  b: TBox;
  queue: TQueue;
  data: TAStarData;
  matrix: T2DBoolArray;
  score, i, hi, size: Int32;
  node: TNode;
  offset, q, p: TPoint;
begin
  b := GetTPABounds(tpa);
  if not b.Contains(start) then Exit;
  if not b.Contains(goal) then Exit;

  offset.X := b.X1;
  offset.Y := b.Y1;
  start.X -= offset.X;
  start.Y -= offset.Y;
  goal.X -= offset.X;
  goal.Y -= offset.Y;

  b.X1 := 0;
  b.Y1 := 0;
  b.X2 -= offset.X;
  b.Y2 -= offset.Y;

  SetLength(matrix, b.Y2+1, b.X2+1);
  for p in tpa do
    matrix[p.Y - offset.Y, p.X - offset.X] := True;

  if not matrix[start.Y, start.X] then Exit;
  if not matrix[goal.Y, goal.X] then Exit;

  SetLength(paths, 0);
  SetLength(paths, offset.Y + b.Y2+1, offset.X + b.X2+1);
  SetLength(data, b.Y2+1, b.X2+1);

  data[start.Y, start.X].ScoreB := Sqr(start.X - goal.X) + Sqr(start.Y - goal.Y);

  node.Pt := start;
  node.Weight := data[start.Y, start.X].ScoreB;
  _Push(queue, node, data, size);

  if diagonalTravel then hi := 7 else hi := 3;

  while (size > 0) do
  begin
    node := _Pop(queue, data, size);
    p := node.Pt;

    if p = goal then Exit(_BuildPath(start, goal, data, offset));

    for i := 0 to hi do
    begin
      q := p + OFFSETS[i];

      if not b.Contains(q) then Continue;
      if not matrix[q.Y, q.X] then Continue;

      score := data[p.Y, p.X].ScoreA + 1;

      if data[q.Y, q.X].Closed and (score >= data[q.Y, q.X].ScoreA) then
        Continue;
      if data[q.Y, q.X].Open and (score >= data[q.Y, q.X].ScoreA) then
        Continue;

      data[q.Y, q.X].Parent := p;
      data[q.Y, q.X].ScoreA := score;
      data[q.Y, q.X].ScoreB := data[q.Y, q.X].ScoreA + Sqr(q.X - goal.X) + Sqr(q.Y - goal.Y);;

      if data[q.Y, q.X].Open then Continue;

      paths[q.Y + offset.Y, q.X + offset.X] := score;

      node.Pt := q;
      node.Weight := data[q.Y, q.X].ScoreB;
      _Push(queue, node, data, size);
    end;
  end;


  Result := [];
end;

function AStarTPA(tpa: TPointArray; start, goal: TPoint; diagonalTravel: Boolean): TPointArray;
const
  OFFSETS: array[0..7] of TPoint = ((X:0; Y:-1),(X:-1; Y:0),(X:1; Y:0),(X:0; Y:1),(X:1; Y:-1),(X:-1; Y:1),(X:1; Y:1),(X:-1; Y:-1));
var
  b: TBox;
  queue: TQueue;
  data: TAStarData;
  matrix: T2DBoolArray;
  score, i, hi, size: Int32;
  node: TNode;
  offset, q, p: TPoint;
begin
  b := GetTPABounds(tpa);
  if not b.Contains(start) then Exit;
  if not b.Contains(goal) then Exit;

  offset.X := b.X1;
  offset.Y := b.Y1;
  start.X -= offset.X;
  start.Y -= offset.Y;
  goal.X -= offset.X;
  goal.Y -= offset.Y;

  b.X1 := 0;
  b.Y1 := 0;
  b.X2 -= offset.X;
  b.Y2 -= offset.Y;

  SetLength(matrix, b.Y2+1, b.X2+1);
  for p in tpa do
    matrix[p.Y - offset.Y, p.X - offset.X] := True;

  if not matrix[start.Y, start.X] then Exit;
  if not matrix[goal.Y, goal.X] then Exit;

  SetLength(data, b.Y2 + 1, b.X2 + 1);

  data[start.Y, start.X].ScoreB := Sqr(start.X - goal.X) + Sqr(start.Y - goal.Y);

  node.Pt := start;
  node.Weight := data[start.Y, start.X].ScoreB;
  _Push(queue, node, data, size);

  if diagonalTravel then hi := 7 else hi := 3;

  while (size > 0) do
  begin
    node := _Pop(queue, data, size);
    p := node.Pt;

    if p = goal then Exit(_BuildPath(start, goal, data, offset));

    for i := 0 to hi do
    begin
      q := p + OFFSETS[i];

      if not b.Contains(q) then Continue;
      if not matrix[q.Y, q.X] then Continue;

      score := data[p.Y, p.X].ScoreA + 1;

      if data[q.Y, q.X].Closed and (score >= data[q.Y, q.X].ScoreA) then
        Continue;
      if data[q.Y, q.X].Open and (score >= data[q.Y, q.X].ScoreA) then
        Continue;

      data[q.Y, q.X].Parent := p;
      data[q.Y, q.X].ScoreA := score;
      data[q.Y, q.X].ScoreB := data[q.Y, q.X].ScoreA + Sqr(q.X - goal.X) + Sqr(q.Y - goal.Y);;

      if data[q.Y, q.X].Open then Continue;

      node.Pt := q;
      node.Weight := data[q.Y, q.X].ScoreB;
      _Push(queue, node, data, size);
    end;
  end;

  Result := [];
end;

end.

